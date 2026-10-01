import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.57.4";
import {
  Contract,
  Interface,
  JsonRpcProvider,
  keccak256,
  toUtf8Bytes,
} from "npm:ethers@6.15.0";

const headers = { "content-type": "application/json; charset=utf-8" };

function out(status: number, body: unknown) {
  return new Response(JSON.stringify(body), { status, headers });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return out(405, { ok: false, error: "method_not_allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return out(500, { ok: false, error: "supabase_environment_missing" });
  }

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const sessionToken = String(req.headers.get("x-club-session") || "").trim();
  if (!sessionToken) return out(401, { ok: false, error: "secure_session_required" });

  const { data: actorId, error: sessionError } = await supabase.rpc(
    "validar_sesion_segura_interno",
    { p_token: sessionToken },
  );
  if (sessionError || !actorId) {
    return out(401, { ok: false, error: "invalid_or_expired_session" });
  }

  const { data: principal, error: principalError } = await supabase
    .from("administradores")
    .select("numero_socio")
    .eq("numero_socio", Number(actorId))
    .eq("habilitado", true)
    .eq("es_principal", true)
    .maybeSingle();

  if (principalError || !principal) {
    return out(403, { ok: false, error: "principal_admin_required" });
  }

  let body: Record<string, unknown> = {};
  try { body = await req.json(); } catch (_) { body = {}; }

  const source = String(body.source || "");
  const batchId = String(body.lote_id || "");
  const txHash = String(body.tx_hash || "").trim();

  if (!["auditoria", "votos"].includes(source) || !batchId || !/^0x[0-9a-fA-F]{64}$/.test(txHash)) {
    return out(400, { ok: false, error: "invalid_request" });
  }

  const { data: cfgRows, error: cfgError } = await supabase
    .from("configuracion_blockchain_publica")
    .select("red,chain_id,contrato,confirmaciones_requeridas")
    .order("version", { ascending: false })
    .limit(1);

  if (cfgError || !cfgRows?.[0]) {
    return out(500, { ok: false, error: "blockchain_config_missing" });
  }

  const cfg = cfgRows[0];
  if (Number(cfg.chain_id) !== 80002) {
    return out(409, { ok: false, error: "manual_test_only_allowed_on_amoy" });
  }

  const table = source === "auditoria" ? "lotes_merkle_auditoria" : "lotes_merkle_votos";
  const fields = source === "auditoria"
    ? "id,referencia,raiz_merkle_sha256,cantidad_eventos,estado,transaccion_hash"
    : "id,referencia,raiz_merkle_sha256,cantidad_hojas,estado,transaccion_hash";

  const { data: batch, error: batchError } = await supabase
    .from(table)
    .select(fields)
    .eq("id", batchId)
    .maybeSingle();

  if (batchError || !batch) {
    return out(404, { ok: false, error: "batch_not_found" });
  }

  const count = source === "auditoria"
    ? Number((batch as Record<string, unknown>).cantidad_eventos)
    : Number((batch as Record<string, unknown>).cantidad_hojas);

  const rpcUrl = Deno.env.get("POLYGON_RPC_URL") || "https://rpc-amoy.polygon.technology/";
  const provider = new JsonRpcProvider(rpcUrl);
  const network = await provider.getNetwork();

  if (Number(network.chainId) !== Number(cfg.chain_id)) {
    return out(409, {
      ok: false,
      error: "unexpected_chain_id",
      expected: Number(cfg.chain_id),
      actual: Number(network.chainId),
    });
  }

  const receipt = await provider.getTransactionReceipt(txHash);
  if (!receipt) return out(409, { ok: false, error: "transaction_not_mined_yet" });
  if (receipt.status !== 1) return out(409, { ok: false, error: "transaction_failed_on_chain" });

  const tx = await provider.getTransaction(txHash);
  if (!tx || !tx.to || tx.to.toLowerCase() !== String(cfg.contrato).toLowerCase()) {
    return out(409, { ok: false, error: "transaction_contract_mismatch" });
  }

  const abi = [
    "function anchor(bytes32 referenceHash, bytes32 merkleRoot, uint64 leafCount) external",
    "function verifyAnchor(bytes32 referenceHash, bytes32 merkleRoot, uint64 leafCount) external view returns (bool)",
  ];
  const iface = new Interface(abi);

  let decoded;
  try {
    decoded = iface.decodeFunctionData("anchor", tx.data);
  } catch (_) {
    return out(409, { ok: false, error: "transaction_is_not_anchor_call" });
  }

  const referenceHash = keccak256(toUtf8Bytes(String((batch as Record<string, unknown>).referencia)));
  const merkleRoot = "0x" + String((batch as Record<string, unknown>).raiz_merkle_sha256);

  if (
    String(decoded[0]).toLowerCase() !== referenceHash.toLowerCase() ||
    String(decoded[1]).toLowerCase() !== merkleRoot.toLowerCase() ||
    BigInt(decoded[2]).toString() !== BigInt(count).toString()
  ) {
    return out(409, { ok: false, error: "anchor_payload_mismatch" });
  }

  const contract = new Contract(String(cfg.contrato), abi, provider);
  const verified = await contract.verifyAnchor(
    referenceHash,
    merkleRoot,
    BigInt(count),
  );

  if (!verified) {
    return out(409, { ok: false, error: "on_chain_verification_false" });
  }

  const { error: updateError } = await supabase
    .from(table)
    .update({
      estado: "anclado",
      red: cfg.red || "polygon-amoy",
      chain_id: Number(cfg.chain_id),
      contrato: String(cfg.contrato),
      transaccion_hash: txHash,
      bloque_numero: receipt.blockNumber,
      enviado_en: (batch as Record<string, unknown>).transaccion_hash ? undefined : new Date().toISOString(),
      anclado_en: new Date().toISOString(),
    })
    .eq("id", batchId);

  if (updateError) {
    return out(500, { ok: false, error: "batch_update_failed", detail: updateError.message });
  }

  await supabase.rpc("registrar_auditoria_interna", {
    p_accion: "LOTE_MERKLE_CONFIRMADO_BLOCKCHAIN_MANUAL",
    p_entidad: table,
    p_entidad_id: batchId,
    p_anteriores: null,
    p_nuevos: {
      tipo_lote: source,
      referencia: (batch as Record<string, unknown>).referencia,
      raiz_merkle_sha256: (batch as Record<string, unknown>).raiz_merkle_sha256,
      cantidad_registros: count,
      red: cfg.red,
      chain_id: Number(cfg.chain_id),
      contrato: cfg.contrato,
      transaccion_hash: txHash,
      bloque_numero: receipt.blockNumber,
    },
    p_actor_hint: Number(actorId),
    p_contexto: {
      modulo: "blockchain",
      modo: "firma_metamask_manual",
      verificado_on_chain: true,
    },
    p_origen: "blockchain_verify_edge",
  });

  return out(200, {
    ok: true,
    verified: true,
    source,
    lote_id: batchId,
    tx_hash: txHash,
    block_number: receipt.blockNumber,
    reference_hash: referenceHash,
  });
});

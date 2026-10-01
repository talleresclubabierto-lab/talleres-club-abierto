import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.57.4";
import {
  Contract,
  JsonRpcProvider,
  Wallet,
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

  const rpcUrl = Deno.env.get("POLYGON_RPC_URL") || "";
  const privateKey = Deno.env.get("BLOCKCHAIN_PRIVATE_KEY") || "";
  const contractAddress = Deno.env.get("BLOCKCHAIN_CONTRACT_ADDRESS") || "";
  const expectedChainId = Deno.env.get("BLOCKCHAIN_CHAIN_ID") || "";

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch (_) {
    body = {};
  }

  const action = String(body.action || "status");

  const { data: batches, error: batchError } = await supabase
    .from("lotes_merkle_auditoria")
    .select(
      "id,referencia,tipo,politica_version,causa_extraordinaria,cantidad_eventos,raiz_merkle_sha256,estado,preparado_en",
    )
    .eq("estado", "preparado")
    .order("preparado_en", { ascending: true })
    .limit(1);

  if (batchError) {
    return out(500, {
      ok: false,
      error: "prepared_batch_query_failed",
      detail: batchError.message,
    });
  }

  const batch = batches?.[0] || null;

  const { data: envioHabilitado, error: envioError } = await supabase
    .rpc("blockchain_envio_habilitado");

  if (envioError) {
    return out(500, {
      ok: false,
      error: "blockchain_operational_state_query_failed",
      detail: envioError.message,
    });
  }

  const configured = {
    rpc: Boolean(rpcUrl),
    private_key: Boolean(privateKey),
    contract: Boolean(contractAddress),
    chain_id: Boolean(expectedChainId),
  };

  if (action === "status") {
    return out(200, {
      ok: true,
      configured,
      operational_state: envioHabilitado === true ? "activa" : "no_activa",
      sending_enabled: envioHabilitado === true,
      ready:
        envioHabilitado === true &&
        Object.values(configured).every(Boolean),
      next_prepared_batch: batch,
    });
  }

  if (action !== "anchor") {
    return out(400, { ok: false, error: "unknown_action" });
  }

  const sessionToken = String(req.headers.get("x-club-session") || "").trim();
  if (!sessionToken) {
    return out(401, { ok: false, error: "secure_session_required" });
  }

  const { data: actorId, error: sessionError } = await supabase.rpc(
    "validar_sesion_segura_interno",
    { p_token: sessionToken },
  );

  if (sessionError || !actorId) {
    return out(401, { ok: false, error: "invalid_or_expired_session" });
  }

  const { data: principal, error: principalError } = await supabase
    .from("administradores")
    .select("numero_socio,es_principal,habilitado")
    .eq("numero_socio", Number(actorId))
    .eq("habilitado", true)
    .eq("es_principal", true)
    .maybeSingle();

  if (principalError || !principal) {
    return out(403, { ok: false, error: "principal_admin_required" });
  }

  if (envioHabilitado !== true) {
    return out(200, {
      ok: true,
      anchored: false,
      reason: "blockchain_integration_not_active",
      sending_enabled: false,
      next_prepared_batch: batch,
    });
  }

  if (!batch) {
    return out(200, {
      ok: true,
      anchored: false,
      reason: "no_prepared_batch",
    });
  }

  if (!Object.values(configured).every(Boolean)) {
    return out(503, {
      ok: false,
      error: "blockchain_environment_not_configured",
      configured,
    });
  }

  try {
    const provider = new JsonRpcProvider(rpcUrl);
    const network = await provider.getNetwork();

    if (network.chainId.toString() !== expectedChainId) {
      return out(409, {
        ok: false,
        error: "unexpected_chain_id",
        expected: expectedChainId,
        actual: network.chainId.toString(),
      });
    }

    const wallet = new Wallet(privateKey, provider);

    const abi = [
      "function anchor(bytes32 referenceHash, bytes32 merkleRoot, uint64 leafCount) external",
      "function verifyAnchor(bytes32 referenceHash, bytes32 merkleRoot, uint64 leafCount) external view returns (bool)",
      "event BatchAnchored(bytes32 indexed referenceHash, bytes32 indexed merkleRoot, uint64 leafCount, uint64 anchoredAt)",
    ];

    const contract = new Contract(contractAddress, abi, wallet);

    const referenceHash = keccak256(toUtf8Bytes(batch.referencia));
    const merkleRoot = "0x" + batch.raiz_merkle_sha256;
    const leafCount = BigInt(batch.cantidad_eventos);

    const tx = await contract.anchor(referenceHash, merkleRoot, leafCount);
    const sentAt = new Date().toISOString();

    const { error: sentError } = await supabase
      .from("lotes_merkle_auditoria")
      .update({
        estado: "enviado",
        red: "polygon",
        chain_id: Number(network.chainId),
        contrato: contractAddress,
        transaccion_hash: tx.hash,
        enviado_en: sentAt,
        metadata: {
          ...(batch.metadata || {}),
          reference_hash: referenceHash,
        },
      })
      .eq("id", batch.id)
      .eq("estado", "preparado");

    if (sentError) {
      throw new Error("No se pudo registrar el envío: " + sentError.message);
    }

    const receipt = await tx.wait(1);
    if (!receipt) {
      throw new Error("No se recibió comprobante de la transacción");
    }

    const verified = await contract.verifyAnchor(
      referenceHash,
      merkleRoot,
      leafCount,
    );

    if (!verified) {
      throw new Error("La verificación on-chain del anclaje devolvió false");
    }

    const { error: confirmedError } = await supabase
      .from("lotes_merkle_auditoria")
      .update({
        estado: "anclado",
        bloque_numero: receipt.blockNumber,
        anclado_en: new Date().toISOString(),
      })
      .eq("id", batch.id)
      .eq("transaccion_hash", tx.hash);

    if (confirmedError) {
      throw new Error(
        "No se pudo registrar la confirmación: " + confirmedError.message,
      );
    }

    await supabase.rpc("registrar_auditoria_interna", {
      p_accion: "LOTE_MERKLE_AUDITORIA_CONFIRMADO_BLOCKCHAIN",
      p_entidad: "lotes_merkle_auditoria",
      p_entidad_id: batch.id,
      p_anteriores: null,
      p_nuevos: {
        referencia: batch.referencia,
        reference_hash: referenceHash,
        raiz_merkle_sha256: batch.raiz_merkle_sha256,
        cantidad_eventos: batch.cantidad_eventos,
        red: "polygon",
        chain_id: Number(network.chainId),
        contrato: contractAddress,
        transaccion_hash: tx.hash,
        bloque_numero: receipt.blockNumber,
      },
      p_actor_hint: null,
      p_contexto: {
        modulo: "blockchain",
        confirmaciones: 1,
        verificado_on_chain: true,
      },
      p_origen: "blockchain_anchor_worker",
    });

    return out(200, {
      ok: true,
      anchored: true,
      lote_id: batch.id,
      referencia: batch.referencia,
      reference_hash: referenceHash,
      tx_hash: tx.hash,
      block_number: receipt.blockNumber,
      chain_id: network.chainId.toString(),
    });
  } catch (error) {
    return out(500, {
      ok: false,
      error: "anchor_failed",
      detail: error instanceof Error ? error.message : String(error),
    });
  }
});

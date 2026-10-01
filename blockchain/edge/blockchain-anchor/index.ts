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

type PreparedBatch = {
  source: "auditoria" | "votos";
  id: string;
  referencia: string;
  raiz_merkle_sha256: string;
  cantidad: number;
  preparado_en: string;
  metadata?: Record<string, unknown> | null;
};

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return out(405, { ok: false, error: "method_not_allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const rpcUrl = Deno.env.get("POLYGON_RPC_URL") || "";
  const privateKey = Deno.env.get("BLOCKCHAIN_PRIVATE_KEY") || "";
  const automationToken = Deno.env.get("BLOCKCHAIN_AUTOMATION_TOKEN") || "";

  if (!supabaseUrl || !serviceKey) {
    return out(500, { ok: false, error: "supabase_environment_missing" });
  }

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

  const { data: envioHabilitado, error: envioError } = await supabase
    .rpc("blockchain_envio_habilitado");

  if (envioError) {
    return out(500, {
      ok: false,
      error: "blockchain_operational_state_query_failed",
      detail: envioError.message,
    });
  }

  const { data: configRows, error: configError } = await supabase
    .from("configuracion_blockchain_publica")
    .select("version,estado_integracion,red,chain_id,contrato,confirmaciones_requeridas")
    .order("version", { ascending: false })
    .limit(1);

  if (configError) {
    return out(500, {
      ok: false,
      error: "blockchain_public_config_query_failed",
      detail: configError.message,
    });
  }

  const config = configRows?.[0] || null;
  const contractAddress = String(config?.contrato || "");
  const expectedChainId = String(config?.chain_id || "");

  const [auditQuery, voteQuery] = await Promise.all([
    supabase
      .from("lotes_merkle_auditoria")
      .select("id,referencia,raiz_merkle_sha256,cantidad_eventos,preparado_en,metadata")
      .eq("estado", "preparado")
      .order("preparado_en", { ascending: true })
      .limit(1),
    supabase
      .from("lotes_merkle_votos")
      .select("id,referencia,raiz_merkle_sha256,cantidad_hojas,preparado_en,metadata")
      .eq("estado", "preparado")
      .order("preparado_en", { ascending: true })
      .limit(1),
  ]);

  if (auditQuery.error || voteQuery.error) {
    return out(500, {
      ok: false,
      error: "prepared_batch_query_failed",
      detail: auditQuery.error?.message || voteQuery.error?.message,
    });
  }

  const candidates: PreparedBatch[] = [];
  const audit = auditQuery.data?.[0];
  if (audit) {
    candidates.push({
      source: "auditoria",
      id: String(audit.id),
      referencia: String(audit.referencia),
      raiz_merkle_sha256: String(audit.raiz_merkle_sha256),
      cantidad: Number(audit.cantidad_eventos),
      preparado_en: String(audit.preparado_en),
      metadata: audit.metadata as Record<string, unknown> | null,
    });
  }
  const vote = voteQuery.data?.[0];
  if (vote) {
    candidates.push({
      source: "votos",
      id: String(vote.id),
      referencia: String(vote.referencia),
      raiz_merkle_sha256: String(vote.raiz_merkle_sha256),
      cantidad: Number(vote.cantidad_hojas),
      preparado_en: String(vote.preparado_en),
      metadata: vote.metadata as Record<string, unknown> | null,
    });
  }

  candidates.sort((a, b) => a.preparado_en.localeCompare(b.preparado_en));
  const batch = candidates[0] || null;

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
      operational_state: config?.estado_integracion || "sin_configuracion",
      sending_enabled: envioHabilitado === true,
      ready:
        envioHabilitado === true &&
        Object.values(configured).every(Boolean),
      public_config: config,
      next_prepared_batch: batch,
    });
  }

  if (action !== "anchor") {
    return out(400, { ok: false, error: "unknown_action" });
  }

  const providedAutomationToken =
    String(req.headers.get("x-club-anchor-automation") || "").trim();
  let authorized = Boolean(
    automationToken &&
    providedAutomationToken &&
    providedAutomationToken === automationToken
  );

  if (!authorized) {
    const sessionToken = String(
      req.headers.get("x-club-session") || ""
    ).trim();

    if (sessionToken) {
      const { data: actorId, error: sessionError } = await supabase.rpc(
        "validar_sesion_segura_interno",
        { p_token: sessionToken },
      );

      if (!sessionError && actorId) {
        const { data: principal } = await supabase
          .from("administradores")
          .select("numero_socio")
          .eq("numero_socio", Number(actorId))
          .eq("habilitado", true)
          .eq("es_principal", true)
          .maybeSingle();

        authorized = Boolean(principal);
      }
    }
  }

  if (!authorized) {
    return out(403, { ok: false, error: "anchor_execution_not_authorized" });
  }

  if (envioHabilitado !== true) {
    return out(200, {
      ok: true,
      anchored: false,
      reason: "blockchain_integration_not_active",
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
    ];

    const contract = new Contract(contractAddress, abi, wallet);
    const referenceHash = keccak256(toUtf8Bytes(batch.referencia));
    const merkleRoot = "0x" + batch.raiz_merkle_sha256;
    const leafCount = BigInt(batch.cantidad);

    const tx = await contract.anchor(referenceHash, merkleRoot, leafCount);
    const sentAt = new Date().toISOString();
    const table =
      batch.source === "auditoria"
        ? "lotes_merkle_auditoria"
        : "lotes_merkle_votos";

    const { error: sentError } = await supabase
      .from(table)
      .update({
        estado: "enviado",
        red: config?.red || "polygon",
        chain_id: Number(network.chainId),
        contrato: contractAddress,
        transaccion_hash: tx.hash,
        enviado_en: sentAt,
        metadata: {
          ...(batch.metadata || {}),
          reference_hash: referenceHash,
          origen_lote: batch.source,
        },
      })
      .eq("id", batch.id)
      .eq("estado", "preparado");

    if (sentError) {
      throw new Error("No se pudo registrar el envío: " + sentError.message);
    }

    const confirmations = Math.max(
      1,
      Number(config?.confirmaciones_requeridas || 1),
    );
    const receipt = await tx.wait(confirmations);
    if (!receipt) throw new Error("No se recibió comprobante de la transacción");

    const verified = await contract.verifyAnchor(
      referenceHash,
      merkleRoot,
      leafCount,
    );
    if (!verified) {
      throw new Error("La verificación on-chain del anclaje devolvió false");
    }

    const { error: confirmedError } = await supabase
      .from(table)
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
      p_accion: "LOTE_MERKLE_CONFIRMADO_BLOCKCHAIN",
      p_entidad: table,
      p_entidad_id: batch.id,
      p_anteriores: null,
      p_nuevos: {
        tipo_lote: batch.source,
        referencia: batch.referencia,
        reference_hash: referenceHash,
        raiz_merkle_sha256: batch.raiz_merkle_sha256,
        cantidad_registros: batch.cantidad,
        red: config?.red || "polygon",
        chain_id: Number(network.chainId),
        contrato: contractAddress,
        transaccion_hash: tx.hash,
        bloque_numero: receipt.blockNumber,
      },
      p_actor_hint: null,
      p_contexto: {
        modulo: "blockchain",
        confirmaciones: confirmations,
        verificado_on_chain: true,
      },
      p_origen: "blockchain_anchor_worker",
    });

    return out(200, {
      ok: true,
      anchored: true,
      source: batch.source,
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

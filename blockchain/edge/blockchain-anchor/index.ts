
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.57.4";
import {
  Contract,
  JsonRpcProvider,
  Wallet,
  keccak256,
  toUtf8Bytes,
} from "npm:ethers@6.15.0";

const headers = {
  "content-type": "application/json; charset=utf-8",
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, x-client-info, apikey, content-type, x-club-session, x-club-anchor-automation, x-club-reconcile-scheduler",
  "access-control-allow-methods": "POST, OPTIONS",
};

function out(status: number, body: unknown) {
  return new Response(JSON.stringify(body), { status, headers });
}

type PreparedBatch = {
  source: "auditoria" | "votos" | "comunidad_formativa";
  id: string;
  referencia: string;
  raiz_merkle_sha256: string;
  cantidad: number;
  preparado_en: string;
  metadata?: Record<string, unknown> | null;
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers });
  }

  if (req.method !== "POST") {
    return out(405, { ok: false, error: "method_not_allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const rpcUrl = Deno.env.get("POLYGON_RPC_URL") || "";
  const privateKey = Deno.env.get("ANCHORER_PRIVATE_KEY") || "";
  const automationToken = Deno.env.get("BLOCKCHAIN_AUTOMATION_TOKEN") || "";

  if (!supabaseUrl || !serviceKey) {
    return out(500, {
      ok: false,
      error: "supabase_environment_missing",
    });
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

  const { data: envioHabilitado, error: envioError } =
    await supabase.rpc("blockchain_envio_habilitado");

  if (envioError) {
    return out(500, {
      ok: false,
      error: "blockchain_operational_state_query_failed",
      detail: envioError.message,
    });
  }

  const { data: configRows, error: configError } = await supabase
    .from("configuracion_blockchain_publica")
    .select(
      "version,estado,estado_integracion,red,chain_id,contrato,confirmaciones_requeridas",
    )
    .eq("estado", "vigente")
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
      .select(
        "id,referencia,raiz_merkle_sha256,cantidad_eventos,preparado_en,metadata",
      )
      .eq("estado", "preparado")
      .order("preparado_en", { ascending: true })
      .limit(1),

    supabase
      .from("lotes_merkle_votos")
      .select(
        "id,referencia,raiz_merkle_sha256,cantidad_hojas,preparado_en,metadata",
      )
      .eq("estado", "preparado")
      .order("preparado_en", { ascending: true })
      .limit(1),

  ]);

  const { data: formativeBatch, error: formativeError } =
    await supabase.rpc("community_formative_anchor_prepared_batch");

  if (auditQuery.error || voteQuery.error || formativeError) {
    return out(500, {
      ok: false,
      error: "prepared_batch_query_failed",
      detail:
        auditQuery.error?.message ||
        voteQuery.error?.message ||
        formativeError?.message,
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

  const formative = formativeBatch && typeof formativeBatch === "object"
    ? formativeBatch as Record<string, unknown>
    : null;
  if (formative) {
    candidates.push({
      source: "comunidad_formativa",
      id: String(formative.id),
      referencia: String(formative.referencia),
      raiz_merkle_sha256: String(formative.raiz_sha256),
      cantidad: Number(formative.cantidad),
      preparado_en: String(formative.preparado_en),
    });
  }

  candidates.sort((a, b) =>
    a.preparado_en.localeCompare(b.preparado_en)
  );

  const batch = candidates[0] || null;

  const configured = {
    rpc: Boolean(rpcUrl),
    anchorer_private_key: Boolean(privateKey),
    contract: Boolean(contractAddress),
    chain_id: Boolean(expectedChainId),
  };

  if (action === "status") {
    return out(200, {
      ok: true,
      configured,
      operational_state:
        config?.estado_integracion || "sin_configuracion",
      sending_enabled: envioHabilitado === true,
      ready:
        envioHabilitado === true &&
        Object.values(configured).every(Boolean),
      public_config: config,
      next_prepared_batch: batch,
    });
  }

  if (action !== "anchor" && action !== "reconcile") {
    return out(400, {
      ok: false,
      error: "unknown_action",
    });
  }

  const providedAutomationToken = String(
    req.headers.get("x-club-anchor-automation") || "",
  ).trim();

  let authorized = Boolean(
    automationToken &&
    providedAutomationToken &&
    providedAutomationToken === automationToken
  );

  // Autorizacion exclusiva del conciliador programado.
  // No permite ejecutar la accion "anchor".
  if (!authorized && action === "reconcile") {
    const schedulerToken = String(
      req.headers.get("x-club-reconcile-scheduler") || "",
    ).trim();

    if (schedulerToken) {
      const { data, error } = await supabase.rpc(
        "blockchain_validar_conciliador",
        { p_token: schedulerToken },
      );

      authorized = !error && data === true;
    }
  }

  if (!authorized) {
    const sessionToken = String(
      req.headers.get("x-club-session") || "",
    ).trim();

    if (sessionToken) {
      const { data: actorId, error: sessionError } =
        await supabase.rpc(
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
    return out(403, {
      ok: false,
      error: "anchor_execution_not_authorized",
    });
  }

  // Conciliacion: nunca firma ni envia transacciones.
  if (action === "reconcile") {
    if (!rpcUrl || !contractAddress || !expectedChainId) {
      return out(503, {
        ok: false,
        error: "reconciliation_environment_missing",
      });
    }

    const provider = new JsonRpcProvider(rpcUrl);
    const network = await provider.getNetwork();

    if (network.chainId.toString() !== expectedChainId) {
      return out(409, {
        ok: false,
        error: "unexpected_chain_id",
      });
    }

    const confirmations = Math.max(
      1,
      Number(config?.confirmaciones_requeridas || 1),
    );

    // Event signature confirmed from a successful Polygon Mainnet receipt.
    // Both referenceHash and merkleRoot are indexed (topics[1] and topics[2]).
    const anchoredTopic =
      "0xfeafecce8fbaa934e4a1842aa3ddc1b372ebf6d0bb12165cad45a6426f42abdd";

    const recovered: unknown[] = [];
    const unresolved: unknown[] = [];

    for (const source of ["auditoria", "votos", "comunidad_formativa"] as const) {
      const table =
        source === "auditoria"
          ? "lotes_merkle_auditoria"
          : source === "votos"
          ? "lotes_merkle_votos"
          : "lotes_merkle";
      const rootField = "raiz_merkle_sha256";
      const countField = source === "auditoria"
        ? "cantidad_eventos"
        : source === "votos"
        ? "cantidad_hojas"
        : "cantidad";

      let pending: Record<string, unknown>[] = [];
      if (source === "comunidad_formativa") {
        const { data, error } = await supabase.rpc("community_formative_anchor_pending_batches");
        if (error) return out(500, { ok: false, error: "reconciliation_query_failed", detail: error.message });
        pending = Array.isArray(data) ? data as Record<string, unknown>[] : [];
      } else {
        const { data, error } = await supabase.from(table)
          .select("id,referencia," + rootField + "," + countField + ",transaccion_hash,estado")
          .eq("estado", "enviado").limit(50);
        if (error) return out(500, { ok: false, error: "reconciliation_query_failed", detail: error.message });
        pending = (data || []) as Record<string, unknown>[];
      }

      for (const item of pending || []) {
        const txHash = String(item.transaccion_hash || "");

        if (!/^0x[0-9a-fA-F]{64}$/.test(txHash)) {
          unresolved.push({
            source,
            id: item.id,
            reason: "missing_transaction_hash_manual_review",
          });
          continue;
        }

        try {
          const receipt =
            await provider.getTransactionReceipt(txHash);

          if (!receipt) {
            unresolved.push({
              source,
              id: item.id,
              reason: "receipt_not_available",
            });
            continue;
          }

          const currentBlock = await provider.getBlockNumber();

          if (
            receipt.status !== 1 ||
            currentBlock - receipt.blockNumber + 1 <
              confirmations ||
            String(receipt.to || "").toLowerCase() !==
              contractAddress.toLowerCase()
          ) {
            unresolved.push({
              source,
              id: item.id,
              reason: "receipt_not_valid_or_unconfirmed",
            });
            continue;
          }

          const referenceHash = keccak256(
            toUtf8Bytes(String(item.referencia)),
          );

          const root =
            "0x" +
            String(item[rootField]).replace(/^0x/, "");

          const count = BigInt(String(item[countField] ?? 0));

          const matchingLog = receipt.logs.some((log) => {
            if (log.address.toLowerCase() !== contractAddress.toLowerCase()) {
              return false;
            }
            if (log.topics.length !== 3) return false;
            if (log.topics[0].toLowerCase() !== anchoredTopic) return false;
            if (log.topics[1].toLowerCase() !== referenceHash.toLowerCase()) return false;
            if (log.topics[2].toLowerCase() !== root.toLowerCase()) return false;
            // ABI-encoded event data: uint64 leafCount followed by timestamp.
            if (!/^0x[0-9a-fA-F]{128}$/.test(log.data)) return false;
            return BigInt("0x" + log.data.slice(2, 66)) === count;
          });

          if (!matchingLog) {
            unresolved.push({
              source,
              id: item.id,
              reason: "anchored_event_mismatch",
            });
            continue;
          }

          const verifier = new Contract(
            contractAddress,
            [
              "function verifyAnchor(bytes32,bytes32,uint64) view returns (bool)",
            ],
            provider,
          );

          if (
            !(await verifier.verifyAnchor(
              referenceHash,
              root,
              count,
            ))
          ) {
            unresolved.push({
              source,
              id: item.id,
              reason: "contract_verification_failed",
            });
            continue;
          }

          let updated = false;
          if (source === "comunidad_formativa") {
            const { data, error: updateError } = await supabase.rpc("community_formative_anchor_confirm", {
              p_id: item.id,
              p_tx_hash: txHash,
              p_red: config?.red || "polygon",
              p_chain_id: Number(network.chainId),
              p_contrato: contractAddress,
              p_bloque: receipt.blockNumber,
            });
            if (updateError) throw updateError;
            updated = data === true;
          } else {
            const { data, error: updateError } = await supabase.from(table)
              .update({
                estado: "anclado",
                bloque_numero: receipt.blockNumber,
                anclado_en: new Date().toISOString(),
              })
              .eq("id", item.id).eq("estado", "enviado").eq("transaccion_hash", txHash)
              .select("id").maybeSingle();
            if (updateError) throw updateError;
            updated = Boolean(data);
          }

          if (updated) {
            recovered.push({
              source,
              id: item.id,
              tx_hash: txHash,
              block_number: receipt.blockNumber,
            });
          }
        } catch (_) {
          unresolved.push({
            source,
            id: item.id,
            reason: "verification_error",
          });
        }
      }
    }

    return out(200, {
      ok: true,
      action: "reconcile",
      broadcast: false,
      recovered,
      unresolved,
      sending_enabled: envioHabilitado === true,
    });
  }

  // No se permite anclar mientras Polygon este desactivado.
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
      "function anchorer() external view returns (address)",
    ];

    const contract = new Contract(
      contractAddress,
      abi,
      wallet,
    );

    const onchainAnchorer = String(
      await contract.anchorer(),
    ).toLowerCase();

    const signerAddress = wallet.address.toLowerCase();

    if (onchainAnchorer !== signerAddress) {
      return out(409, {
        ok: false,
        error: "configured_signer_is_not_onchain_anchorer",
        signer: wallet.address,
        anchorer: onchainAnchorer,
      });
    }

    const referenceHash = keccak256(
      toUtf8Bytes(batch.referencia),
    );

    const merkleRoot = "0x" + batch.raiz_merkle_sha256;
    const leafCount = BigInt(batch.cantidad);

    const table =
      batch.source === "auditoria"
        ? "lotes_merkle_auditoria"
        : batch.source === "votos"
        ? "lotes_merkle_votos"
        : "lotes_merkle";


    const { data: stillEnabled, error: gateError } =
      await supabase.rpc("blockchain_envio_habilitado");

    if (gateError || stillEnabled !== true) {
      return out(409, {
        ok: false,
        error: "blockchain_integration_not_active",
      });
    }

    const claimTime = new Date().toISOString();

    let claimed: unknown = null;
    let claimError: { message: string } | null = null;
    if (batch.source === "comunidad_formativa") {
      const { data, error } = await supabase.rpc("community_formative_anchor_claim", { p_id: batch.id });
      claimError = error;
      claimed = data === true ? { id: batch.id } : null;
    } else {
      const { data, error } = await supabase.from(table)
        .update({
          estado: "enviado",
          enviado_en: claimTime,
          metadata: {
            ...(batch.metadata || {}),
            reference_hash: referenceHash,
            origen_lote: batch.source,
            envio_reservado_en: claimTime,
            envio_estado: "reservado_sin_tx",
          },
        })
        .eq("id", batch.id).eq("estado", "preparado").select("id").maybeSingle();
      claimError = error;
      claimed = data;
    }

    if (claimError) {
      throw new Error(
        "No se pudo reservar el lote: " +
        claimError.message,
      );
    }

    if (!claimed) {
      return out(200, {
        ok: true,
        anchored: false,
        reason: "batch_claimed_by_other_worker",
      });
    }

    const tx = await contract.anchor(
      referenceHash,
      merkleRoot,
      leafCount,
    );

    let recorded: unknown = null;
    let sentError: { message: string } | null = null;
    if (batch.source === "comunidad_formativa") {
      const { data, error } = await supabase.rpc("community_formative_anchor_record_tx", {
        p_id: batch.id,
        p_tx_hash: tx.hash,
        p_red: config?.red || "polygon",
        p_chain_id: Number(network.chainId),
        p_contrato: contractAddress,
      });
      sentError = error;
      recorded = data === true ? { id: batch.id } : null;
    } else {
      const { data, error } = await supabase.from(table)
        .update({
          red: config?.red || "polygon",
          chain_id: Number(network.chainId),
          contrato: contractAddress,
          transaccion_hash: tx.hash,
          metadata: {
            ...(batch.metadata || {}),
            reference_hash: referenceHash,
            origen_lote: batch.source,
            envio_reservado_en: claimTime,
            envio_estado: "transaccion_emitida",
          },
        })
        .eq("id", batch.id).eq("estado", "enviado").is("transaccion_hash", null).select("id").maybeSingle();
      sentError = error;
      recorded = data;
    }

    if (sentError || !recorded) {
      throw new Error(
        "No se pudo registrar el hash de transaccion; requiere conciliacion manual",
      );
    }

    const confirmations = Math.max(
      1,
      Number(config?.confirmaciones_requeridas || 1),
    );

    const receipt = await tx.wait(confirmations);

    if (!receipt) {
      throw new Error(
        "No se recibio comprobante de la transaccion",
      );
    }

    const verified = await contract.verifyAnchor(
      referenceHash,
      merkleRoot,
      leafCount,
    );

    if (!verified) {
      throw new Error(
        "La verificacion on-chain devolvio false",
      );
    }

    let confirmedError: { message: string } | null = null;
    if (batch.source === "comunidad_formativa") {
      const { data, error } = await supabase.rpc("community_formative_anchor_confirm", {
        p_id: batch.id,
        p_tx_hash: tx.hash,
        p_red: config?.red || "polygon",
        p_chain_id: Number(network.chainId),
        p_contrato: contractAddress,
        p_bloque: receipt.blockNumber,
      });
      confirmedError = error;
      if (!error && data !== true) confirmedError = { message: "community batch confirmation did not apply" };
    } else {
      const { error } = await supabase.from(table)
        .update({
          estado: "anclado",
          bloque_numero: receipt.blockNumber,
          anclado_en: new Date().toISOString(),
        })
        .eq("id", batch.id).eq("transaccion_hash", tx.hash);
      confirmedError = error;
    }

    if (confirmedError) {
      throw new Error(
        "No se pudo registrar la confirmacion: " +
        confirmedError.message,
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
      detail:
        error instanceof Error
          ? error.message
          : String(error),
    });
  }
});

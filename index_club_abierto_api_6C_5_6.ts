// ============================================================
// CLUB ABIERTO / TALLERES DIGITAL
// ETAPA 6B-5O.2
//
// API REAL DE SESIONES
//
// acciones:
//   login
//   validar_sesion
//   cambiar_password
//   resetear_password_admin
//   logout
//
// IMPORTANTE:
// - La contraseña se procesa únicamente en servidor.
// - El token nace únicamente en servidor.
// - PostgreSQL almacena sólo SHA-256 del token.
// - El rol administrativo se informa como dato de interfaz,
//   pero cualquier acción sensible deberá revalidarlo.
// ============================================================

import { createClient } from "jsr:@supabase/supabase-js@2";


// ============================================================
// CORS
// ============================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-club-session",
  "Access-Control-Allow-Methods":
    "POST, OPTIONS",
  "Content-Type":
    "application/json; charset=utf-8",
};


// ============================================================
// RESPUESTA JSON
// ============================================================

function respuesta(
  body: Record<string, unknown>,
  status = 200
) {
  return new Response(
    JSON.stringify(body),
    {
      status,
      headers: corsHeaders,
    }
  );
}


// ============================================================
// SECRET KEY SERVIDOR
// ============================================================

function obtenerSecretKey(): string {

  const raw =
    Deno.env.get("SUPABASE_SECRET_KEYS");

  if (!raw) {
    throw new Error(
      "SUPABASE_SECRET_KEYS no disponible"
    );
  }

  if (raw.startsWith("sb_secret_")) {
    return raw;
  }

  const parsed =
    JSON.parse(raw);

  if (typeof parsed === "string") {
    return parsed;
  }

  if (Array.isArray(parsed)) {

    const key =
      parsed.find(
        (v) =>
          typeof v === "string" &&
          v.startsWith("sb_secret_")
      );

    if (key) return key;
  }

  if (
    parsed &&
    typeof parsed === "object"
  ) {

    const key =
      Object.values(parsed).find(
        (v) =>
          typeof v === "string" &&
          v.startsWith("sb_secret_")
      );

    if (typeof key === "string") {
      return key;
    }
  }

  throw new Error(
    "No se pudo resolver secret key"
  );
}


// ============================================================
// SHA-256 DE CONTRASEÑA
// ============================================================

async function sha256(
  texto: string
): Promise<string> {

  const datos =
    new TextEncoder().encode(texto);

  const digest =
    await crypto.subtle.digest(
      "SHA-256",
      datos
    );

  return Array.from(
    new Uint8Array(digest)
  )
    .map(
      (b) =>
        b.toString(16).padStart(2, "0")
    )
    .join("");
}


// ============================================================
// HASH HISTÓRICO FNV1A
// ============================================================

function hashFallback(
  texto: string
): string {

  let h = 2166136261;

  for (
    let i = 0;
    i < texto.length;
    i++
  ) {
    h ^= texto.charCodeAt(i);
    h = Math.imul(
      h,
      16777619
    );
  }

  return (
    "fallback_" +
    (h >>> 0).toString(16)
  );
}


// ============================================================
// TOKEN SEGURO
// 32 bytes = 256 bits
// ============================================================

function generarTokenSeguro(): string {

  const bytes =
    new Uint8Array(32);

  crypto.getRandomValues(bytes);

  let binario = "";

  for (const b of bytes) {
    binario +=
      String.fromCharCode(b);
  }

  return btoa(binario)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}


// ============================================================
// OBTENER TOKEN DE SESIÓN
//
// Preferencia:
// X-Club-Session
//
// Para las pruebas 6B-5I también aceptamos:
// body.token
// ============================================================

function obtenerTokenSesion(
  req: Request,
  body: Record<string, unknown>
): string {

  const header =
    req.headers.get(
      "x-club-session"
    );

  if (header) {
    return header.trim();
  }

  return String(
    body.token || ""
  ).trim();
}


// ============================================================
// SERVIDOR
// ============================================================

Deno.serve(
  async (req: Request) => {

    if (
      req.method === "OPTIONS"
    ) {

      return new Response(
        null,
        {
          status: 204,
          headers: corsHeaders,
        }
      );
    }


    if (
      req.method !== "POST"
    ) {

      return respuesta(
        {
          ok: false,
          error:
            "Método no permitido",
        },
        405
      );
    }


    try {

      const supabaseUrl =
        Deno.env.get(
          "SUPABASE_URL"
        );

      if (!supabaseUrl) {
        throw new Error(
          "SUPABASE_URL no disponible"
        );
      }


      const supabaseAdmin =
        createClient(
          supabaseUrl,
          obtenerSecretKey(),
          {
            auth: {
              persistSession:
                false,
              autoRefreshToken:
                false,
            },
          }
        );


      const body =
        await req.json()
          .catch(() => ({}));


      const accion =
        String(
          body.accion || ""
        )
          .trim()
          .toLowerCase();


      // ======================================================
      // ACCIÓN: LOGIN
      // ======================================================

      if (
        accion === "login"
      ) {

        const numeroSocio =
          Number(
            body.numero_socio
          );

        const password =
          String(
            body.password || ""
          );


        if (
          !Number.isInteger(
            numeroSocio
          ) ||
          numeroSocio <= 0 ||
          !password
        ) {

          return respuesta(
            {
              ok: false,
              credenciales_validas:
                false,
              mensaje:
                "Número de socio o contraseña incorrectos",
            },
            401
          );
        }


        // ----------------------------------------------------
        // Socio habilitado
        // ----------------------------------------------------

        const socio =
          await supabaseAdmin
            .from("socios")
            .select(
              "numero_socio,nombre,fecha_alta,habilitado"
            )
            .eq(
              "numero_socio",
              numeroSocio
            )
            .maybeSingle();


        if (
          socio.error ||
          !socio.data ||
          socio.data.habilitado !==
            true
        ) {

          return respuesta(
            {
              ok: false,
              credenciales_validas:
                false,
              mensaje:
                "Número de socio o contraseña incorrectos",
            },
            401
          );
        }


        // ----------------------------------------------------
        // Verificación de contraseña
        // ----------------------------------------------------

        const hashPrincipal =
          await sha256(
            password
          );


        let verificacion =
          await supabaseAdmin.rpc(
            "verificar_clave_socio",
            {
              p_numero_socio:
                numeroSocio,

              p_password_hash:
                hashPrincipal,
            }
          );


        let claveCorrecta =
          !verificacion.error &&
          verificacion.data ===
            true;


        // ----------------------------------------------------
        // Compatibilidad histórica
        // ----------------------------------------------------

        if (!claveCorrecta) {

          const alternativo =
            hashFallback(
              password
            );


          verificacion =
            await supabaseAdmin.rpc(
              "verificar_clave_socio",
              {
                p_numero_socio:
                  numeroSocio,

                p_password_hash:
                  alternativo,
              }
            );


          claveCorrecta =
            !verificacion.error &&
            verificacion.data ===
              true;
        }


        if (!claveCorrecta) {

          return respuesta(
            {
              ok: false,
              credenciales_validas:
                false,
              mensaje:
                "Número de socio o contraseña incorrectos",
            },
            401
          );
        }


        // ----------------------------------------------------
        // Determinar administrador
        //
        // Sólo dato de interfaz.
        // NO constituye autorización futura.
        // ----------------------------------------------------

        const admin =
          await supabaseAdmin
            .from(
              "administradores"
            )
            .select(
              "numero_socio,es_principal,habilitado"
            )
            .eq(
              "numero_socio",
              numeroSocio
            )
            .eq(
              "habilitado",
              true
            )
            .maybeSingle();


        const esAdministrador =
          !admin.error &&
          !!admin.data;


        const esPrincipal =
          esAdministrador &&
          admin.data
            ?.es_principal ===
            true;


        // ----------------------------------------------------
        // Crear token
        // ----------------------------------------------------

        const token =
          generarTokenSeguro();


        // ----------------------------------------------------
        // Crear sesión persistente
        // ----------------------------------------------------

        const crear =
          await supabaseAdmin.rpc(
            "crear_sesion_segura_interno",
            {
              p_numero_socio:
                numeroSocio,

              p_token:
                token,

              p_duracion_minutos:
                60,

              p_origen:
                "web",

              p_metadata: {
                api:
                  "club-abierto-api",
                etapa:
                  "6B-5I",
              },
            }
          );


        if (crear.error) {

          throw new Error(
            "No pudo crearse la sesión: " +
            crear.error.message
          );
        }


        // ----------------------------------------------------
        // ÉXITO
        //
        // ÉSTA ES LA ÚNICA RESPUESTA
        // QUE ENTREGA EL TOKEN.
        // ----------------------------------------------------

        return respuesta({
          ok: true,

          accion:
            "login",

          credenciales_validas:
            true,

          numero_socio:
            numeroSocio,

          nombre:
            socio.data.nombre,

          fecha_alta:
            socio.data.fecha_alta,

          es_administrador:
            esAdministrador,

          es_principal:
            esPrincipal,

          sesion_id:
            Number(
              crear.data
            ),

          expires_in_seconds:
            3600,

          token:
            token,
        });
      }


      // ======================================================
      // ACCIÓN: VALIDAR SESIÓN
      // ======================================================

      if (
        accion ===
        "validar_sesion"
      ) {

        const token =
          obtenerTokenSesion(
            req,
            body
          );


        if (!token) {

          return respuesta(
            {
              ok: false,
              sesion_valida:
                false,
              mensaje:
                "Sesión requerida",
            },
            401
          );
        }


        const validar =
          await supabaseAdmin.rpc(
            "validar_sesion_segura_interno",
            {
              p_token:
                token,
            }
          );


        if (
          validar.error ||
          !validar.data
        ) {

          return respuesta(
            {
              ok: false,
              sesion_valida:
                false,
              mensaje:
                "Sesión inválida, vencida o revocada",
            },
            401
          );
        }


        const numeroSocio =
          Number(
            validar.data
          );


        // ----------------------------------------------------
        // Registrar actividad
        // ----------------------------------------------------

        const uso =
          await supabaseAdmin.rpc(
            "actualizar_uso_sesion_segura_interno",
            {
              p_token:
                token,
            }
          );


        if (uso.error) {
          throw new Error(
            "No pudo actualizarse el uso de la sesión"
          );
        }


        // ----------------------------------------------------
        // Perfil básico
        // ----------------------------------------------------

        const socio =
          await supabaseAdmin
            .from("socios")
            .select(
              "numero_socio,nombre,fecha_alta,habilitado"
            )
            .eq(
              "numero_socio",
              numeroSocio
            )
            .single();


        if (
          socio.error ||
          !socio.data
        ) {
          throw new Error(
            "No pudo recuperarse el socio de la sesión"
          );
        }


        // ----------------------------------------------------
        // Rol actual
        // ----------------------------------------------------

        const admin =
          await supabaseAdmin
            .from(
              "administradores"
            )
            .select(
              "es_principal,habilitado"
            )
            .eq(
              "numero_socio",
              numeroSocio
            )
            .eq(
              "habilitado",
              true
            )
            .maybeSingle();


        return respuesta({
          ok: true,

          accion:
            "validar_sesion",

          sesion_valida:
            true,

          numero_socio:
            numeroSocio,

          nombre:
            socio.data.nombre,

          fecha_alta:
            socio.data.fecha_alta,

          es_administrador:
            !admin.error &&
            !!admin.data,

          es_principal:
            !admin.error &&
            admin.data
              ?.es_principal ===
              true,
        });
      }


      // ======================================================
      // ACCIÓN: CAMBIAR PASSWORD
      //
      // Seguridad:
      // - Requiere una sesión vigente.
      // - El socio se obtiene EXCLUSIVAMENTE de esa sesión.
      // - No se acepta numero_socio enviado por el navegador.
      // - La contraseña actual se valida únicamente en servidor.
      // - La contraseña nueva se transforma a SHA-256 en servidor.
      // ======================================================

      if (
        accion === "cambiar_password"
      ) {

        const token =
          obtenerTokenSesion(
            req,
            body
          );

        if (!token) {

          return respuesta(
            {
              ok: false,
              password_actualizado:
                false,
              mensaje:
                "Sesión requerida",
            },
            401
          );
        }


        // ----------------------------------------------------
        // Validar sesión y obtener el socio real
        // ----------------------------------------------------

        const validar =
          await supabaseAdmin.rpc(
            "validar_sesion_segura_interno",
            {
              p_token:
                token,
            }
          );

        if (
          validar.error ||
          !validar.data
        ) {

          return respuesta(
            {
              ok: false,
              password_actualizado:
                false,
              mensaje:
                "Sesión inválida, vencida o revocada",
            },
            401
          );
        }

        const numeroSocio =
          Number(
            validar.data
          );


        // ----------------------------------------------------
        // Validar la contraseña ACTUAL en servidor.
        // El navegador sólo la transmite por HTTPS a esta
        // Edge Function; nunca calcula ni compara el hash.
        // ----------------------------------------------------

        const passwordActual =
          String(
            body.password_actual || ""
          );

        if (!passwordActual) {

          return respuesta(
            {
              ok: false,
              password_actualizado:
                false,
              mensaje:
                "La contraseña actual es obligatoria",
            },
            400
          );
        }

        const hashActual =
          await sha256(
            passwordActual
          );

        let verificacionActual =
          await supabaseAdmin.rpc(
            "verificar_clave_socio",
            {
              p_numero_socio:
                numeroSocio,

              p_password_hash:
                hashActual,
            }
          );

        let claveActualCorrecta =
          !verificacionActual.error &&
          verificacionActual.data ===
            true;

        // Compatibilidad con claves históricas FNV1A.
        if (!claveActualCorrecta) {

          const hashActualAlternativo =
            hashFallback(
              passwordActual
            );

          verificacionActual =
            await supabaseAdmin.rpc(
              "verificar_clave_socio",
              {
                p_numero_socio:
                  numeroSocio,

                p_password_hash:
                  hashActualAlternativo,
              }
            );

          claveActualCorrecta =
            !verificacionActual.error &&
            verificacionActual.data ===
              true;
        }

        if (!claveActualCorrecta) {

          return respuesta(
            {
              ok: false,
              password_actualizado:
                false,
              mensaje:
                "La contraseña actual es incorrecta",
            },
            401
          );
        }


        // ----------------------------------------------------
        // Validar formato de la nueva contraseña
        // Regla vigente del frontend: 8 caracteres
        // alfanuméricos.
        // ----------------------------------------------------

        const nuevaPassword =
          String(
            body.nueva_password || ""
          ).trim();

        if (
          !/^[A-Za-z0-9]{8}$/.test(
            nuevaPassword
          )
        ) {

          return respuesta(
            {
              ok: false,
              password_actualizado:
                false,
              mensaje:
                "La nueva contraseña debe tener exactamente 8 caracteres alfanuméricos",
            },
            400
          );
        }


        // ----------------------------------------------------
        // Hash únicamente en servidor
        // ----------------------------------------------------

        const nuevoHash =
          await sha256(
            nuevaPassword
          );


        // ----------------------------------------------------
        // Actualizar exclusivamente la credencial del socio
        // asociado a la sesión.
        // ----------------------------------------------------

        const actualizar =
          await supabaseAdmin.rpc(
            "actualizar_hash_clave_socio",
            {
              p_numero_socio:
                numeroSocio,

              p_nuevo_hash:
                nuevoHash,

              p_algoritmo:
                "sha256",
            }
          );

        if (actualizar.error) {
          throw new Error(
            "No pudo actualizarse la contraseña: " +
            actualizar.error.message
          );
        }

        if (!actualizar.data) {
          throw new Error(
            "No se encontró la credencial del socio"
          );
        }


        // ----------------------------------------------------
        // Registrar actividad de la sesión
        // ----------------------------------------------------

        const uso =
          await supabaseAdmin.rpc(
            "actualizar_uso_sesion_segura_interno",
            {
              p_token:
                token,
            }
          );

        if (uso.error) {
          throw new Error(
            "La contraseña fue actualizada, pero no pudo registrarse el uso de la sesión"
          );
        }


        return respuesta({
          ok: true,

          accion:
            "cambiar_password",

          password_actualizado:
            true,

          numero_socio:
            numeroSocio,
        });
      }


      // ======================================================
      // ACCIÓN: RESETEAR PASSWORD (ADMIN)
      //
      // Seguridad:
      // - Requiere una sesión vigente.
      // - La identidad del administrador sale EXCLUSIVAMENTE
      //   de la sesión; nunca del body enviado por navegador.
      // - Se revalida en tiempo real que el actor siga siendo
      //   administrador habilitado.
      // - numero_socio_objetivo identifica únicamente al socio
      //   cuya clave debe volver a 1913.
      // ======================================================

      if (
        accion === "resetear_password_admin"
      ) {

        const token =
          obtenerTokenSesion(
            req,
            body
          );

        if (!token) {

          return respuesta(
            {
              ok: false,
              password_reseteado:
                false,
              mensaje:
                "Sesión requerida",
            },
            401
          );
        }


        // ----------------------------------------------------
        // Validar sesión y obtener al actor real
        // ----------------------------------------------------

        const validar =
          await supabaseAdmin.rpc(
            "validar_sesion_segura_interno",
            {
              p_token:
                token,
            }
          );

        if (
          validar.error ||
          !validar.data
        ) {

          return respuesta(
            {
              ok: false,
              password_reseteado:
                false,
              mensaje:
                "Sesión inválida, vencida o revocada",
            },
            401
          );
        }

        const numeroSocioActor =
          Number(
            validar.data
          );


        // ----------------------------------------------------
        // Revalidar autorización administrativa actual
        // ----------------------------------------------------

        const admin =
          await supabaseAdmin
            .from(
              "administradores"
            )
            .select(
              "numero_socio,es_principal,habilitado"
            )
            .eq(
              "numero_socio",
              numeroSocioActor
            )
            .eq(
              "habilitado",
              true
            )
            .maybeSingle();

        if (
          admin.error ||
          !admin.data
        ) {

          return respuesta(
            {
              ok: false,
              password_reseteado:
                false,
              mensaje:
                "Acción permitida únicamente a administradores habilitados",
            },
            403
          );
        }


        // ----------------------------------------------------
        // Validar socio objetivo
        // ----------------------------------------------------

        const numeroSocioObjetivo =
          Number(
            body.numero_socio_objetivo
          );

        if (
          !Number.isInteger(
            numeroSocioObjetivo
          ) ||
          numeroSocioObjetivo <= 0
        ) {

          return respuesta(
            {
              ok: false,
              password_reseteado:
                false,
              mensaje:
                "Número de socio objetivo inválido",
            },
            400
          );
        }


        // ----------------------------------------------------
        // Resetear a la clave institucional 1913
        // ----------------------------------------------------

        const resetear =
          await supabaseAdmin.rpc(
            "resetear_clave_socio_1913",
            {
              p_numero_socio:
                numeroSocioObjetivo,
            }
          );

        if (resetear.error) {
          throw new Error(
            "No pudo resetearse la contraseña: " +
            resetear.error.message
          );
        }

        if (!resetear.data) {

          return respuesta(
            {
              ok: false,
              password_reseteado:
                false,
              mensaje:
                "No se encontró la credencial del socio objetivo",
            },
            404
          );
        }


        // ----------------------------------------------------
        // Registrar actividad de la sesión administrativa
        // ----------------------------------------------------

        const uso =
          await supabaseAdmin.rpc(
            "actualizar_uso_sesion_segura_interno",
            {
              p_token:
                token,
            }
          );

        if (uso.error) {
          throw new Error(
            "La contraseña fue reseteada, pero no pudo registrarse el uso de la sesión"
          );
        }


        return respuesta({
          ok: true,

          accion:
            "resetear_password_admin",

          password_reseteado:
            true,

          numero_socio_objetivo:
            numeroSocioObjetivo,

          actor_numero_socio:
            numeroSocioActor,
        });
      }


      // ======================================================
      // ACCIÓN: PERFIL DE AUDITORÍA ECONÓMICA
      //
      // Seguridad:
      // - Requiere una sesión vigente.
      // - La identidad del socio sale EXCLUSIVAMENTE de la sesión.
      // - El navegador no puede elegir ni suplantar numero_socio.
      // - La función interna aplica antigüedad, puntos, nivel y permisos.
      // ======================================================

      if (
        accion === "perfil_auditoria_economica"
      ) {

        const token =
          obtenerTokenSesion(
            req,
            body
          );

        if (!token) {
          return respuesta(
            {
              ok: false,
              mensaje: "Sesión requerida",
            },
            401
          );
        }

        const validar =
          await supabaseAdmin.rpc(
            "validar_sesion_segura_interno",
            {
              p_token: token,
            }
          );

        if (
          validar.error ||
          !validar.data
        ) {
          return respuesta(
            {
              ok: false,
              mensaje: "Sesión inválida, vencida o revocada",
            },
            401
          );
        }

        const numeroSocio =
          Number(
            validar.data
          );

        const perfil =
          await supabaseAdmin.rpc(
            "perfil_auditoria_economica_interno",
            {
              p_actor: numeroSocio,
            }
          );

        if (perfil.error) {
          throw new Error(
            "No pudo recuperarse el perfil de auditoría económica: " +
            perfil.error.message
          );
        }

        const filaPerfil =
          Array.isArray(perfil.data)
            ? perfil.data[0]
            : perfil.data;

        if (!filaPerfil) {
          return respuesta(
            {
              ok: false,
              mensaje: "No existe perfil de auditoría económica para el socio habilitado",
            },
            404
          );
        }

        const uso =
          await supabaseAdmin.rpc(
            "actualizar_uso_sesion_segura_interno",
            {
              p_token: token,
            }
          );

        if (uso.error) {
          throw new Error(
            "No pudo actualizarse el uso de la sesión"
          );
        }

        return respuesta({
          ok: true,
          accion: "perfil_auditoria_economica",
          numero_socio: numeroSocio,
          antiguedad_anos: Number(filaPerfil.antiguedad_anos),
          puntos_voto: Number(filaPerfil.puntos_voto),
          nivel_auditoria: Number(filaPerfil.nivel_auditoria),
          nivel_nombre: filaPerfil.nivel_nombre,
          permisos: filaPerfil.permisos || {},
        });
      }


      // ======================================================
      // ACCIÓN: DASHBOARD ECONÓMICO
      //
      // Seguridad:
      // - Requiere una sesión vigente.
      // - La identidad del socio sale EXCLUSIVAMENTE de la sesión.
      // - El navegador sólo indica el ejercicio económico a consultar.
      // - Los permisos y el nivel se aplican dentro de Supabase.
      // ======================================================

      if (
        accion === "dashboard_economico"
      ) {

        const token =
          obtenerTokenSesion(
            req,
            body
          );

        if (!token) {
          return respuesta(
            {
              ok: false,
              mensaje: "Sesión requerida",
            },
            401
          );
        }

        const validar =
          await supabaseAdmin.rpc(
            "validar_sesion_segura_interno",
            {
              p_token: token,
            }
          );

        if (
          validar.error ||
          !validar.data
        ) {
          return respuesta(
            {
              ok: false,
              mensaje: "Sesión inválida, vencida o revocada",
            },
            401
          );
        }

        const numeroSocio =
          Number(
            validar.data
          );

        const ejercicioId =
          Number(
            body?.ejercicio_id
          );

        if (
          !Number.isInteger(ejercicioId) ||
          ejercicioId <= 0
        ) {
          return respuesta(
            {
              ok: false,
              mensaje: "ejercicio_id inválido",
            },
            400
          );
        }

        const dashboard =
          await supabaseAdmin.rpc(
            "consultar_dashboard_economico_interno",
            {
              p_actor: numeroSocio,
              p_ejercicio_id: ejercicioId,
            }
          );

        if (dashboard.error) {
          throw new Error(
            "No pudo recuperarse el dashboard económico: " +
            dashboard.error.message
          );
        }

        const uso =
          await supabaseAdmin.rpc(
            "actualizar_uso_sesion_segura_interno",
            {
              p_token: token,
            }
          );

        if (uso.error) {
          throw new Error(
            "No pudo actualizarse el uso de la sesión"
          );
        }

        return respuesta({
          ok: true,
          accion: "dashboard_economico",
          ejercicio_id: ejercicioId,
          datos: Array.isArray(dashboard.data)
            ? dashboard.data
            : dashboard.data
              ? [dashboard.data]
              : [],
        });
      }


      // ======================================================
      // ACCIÓN: BALANCE CONTABLE
      //
      // Seguridad:
      // - Requiere una sesión vigente enviada por X-Club-Session.
      // - La identidad del socio sale EXCLUSIVAMENTE de la sesión.
      // - El navegador sólo indica el ejercicio económico.
      // - La función interna controla publicación, nivel y permisos.
      // ======================================================

      if (
        accion === "balance_contable"
      ) {

        const token =
          String(
            req.headers.get(
              "x-club-session"
            ) || ""
          ).trim();

        if (!token) {
          return respuesta(
            {
              ok: false,
              mensaje: "Sesión requerida",
            },
            401
          );
        }

        const validar =
          await supabaseAdmin.rpc(
            "validar_sesion_segura_interno",
            {
              p_token: token,
            }
          );

        if (
          validar.error ||
          validar.data === null ||
          validar.data === undefined
        ) {
          return respuesta(
            {
              ok: false,
              mensaje: "Sesión inválida o vencida",
            },
            401
          );
        }

        const numeroSocio =
          Number(
            validar.data
          );

        const ejercicioId =
          Number(
            body?.ejercicio_id
          );

        if (
          !Number.isInteger(ejercicioId) ||
          ejercicioId <= 0
        ) {
          return respuesta(
            {
              ok: false,
              mensaje: "ejercicio_id inválido",
            },
            400
          );
        }

        const balance =
          await supabaseAdmin.rpc(
            "consultar_balance_contable_interno",
            {
              p_actor: numeroSocio,
              p_ejercicio_id: ejercicioId,
            }
          );

        if (balance.error) {
          throw new Error(
            "No pudo recuperarse el Balance contable: " +
            balance.error.message
          );
        }

        const uso =
          await supabaseAdmin.rpc(
            "actualizar_uso_sesion_segura_interno",
            {
              p_token: token,
            }
          );

        if (uso.error) {
          throw new Error(
            "No pudo actualizarse el uso de la sesión"
          );
        }

        return respuesta({
          ok: true,
          accion: "balance_contable",
          ejercicio_id: ejercicioId,
          balance: Array.isArray(balance.data)
            ? balance.data
            : balance.data
              ? [balance.data]
              : [],
        });
      }


      // ======================================================
      // ACCIÓN: MOVIMIENTOS ECONÓMICOS
      //
      // Seguridad:
      // - Requiere una sesión vigente.
      // - El token se obtiene EXCLUSIVAMENTE de X-Club-Session.
      // - La identidad del socio sale EXCLUSIVAMENTE de la sesión.
      // - El navegador sólo indica el ejercicio y el límite a consultar.
      // - Los permisos, restricciones y nivel se aplican dentro de Supabase.
      // ======================================================

      if (
        accion === "movimientos_economicos"
      ) {

        const token =
          String(
            req.headers.get(
              "x-club-session"
            ) || ""
          ).trim();

        if (!token) {
          return respuesta(
            {
              ok: false,
              mensaje: "Sesión requerida",
            },
            401
          );
        }

        const validar =
          await supabaseAdmin.rpc(
            "validar_sesion_segura_interno",
            {
              p_token: token,
            }
          );

        if (
          validar.error ||
          !validar.data
        ) {
          return respuesta(
            {
              ok: false,
              mensaje: "Sesión inválida, vencida o revocada",
            },
            401
          );
        }

        const numeroSocio =
          Number(
            validar.data
          );

        const ejercicioId =
          Number(
            body?.ejercicio_id
          );

        if (
          !Number.isInteger(ejercicioId) ||
          ejercicioId <= 0
        ) {
          return respuesta(
            {
              ok: false,
              mensaje: "ejercicio_id inválido",
            },
            400
          );
        }

        const limite =
          Number(
            body?.limite
          );

        if (
          !Number.isInteger(limite) ||
          limite <= 0
        ) {
          return respuesta(
            {
              ok: false,
              mensaje: "limite inválido",
            },
            400
          );
        }

        const movimientos =
          await supabaseAdmin.rpc(
            "consultar_movimientos_economicos_interno",
            {
              p_actor: numeroSocio,
              p_ejercicio_id: ejercicioId,
              p_limite: limite,
            }
          );

        if (movimientos.error) {
          throw new Error(
            "No pudieron recuperarse los movimientos económicos: " +
            movimientos.error.message
          );
        }

        const uso =
          await supabaseAdmin.rpc(
            "actualizar_uso_sesion_segura_interno",
            {
              p_token: token,
            }
          );

        if (uso.error) {
          throw new Error(
            "No pudo actualizarse el uso de la sesión"
          );
        }

        return respuesta({
          ok: true,
          accion: "movimientos_economicos",
          ejercicio_id: ejercicioId,
          limite: limite,
          movimientos: Array.isArray(movimientos.data)
            ? movimientos.data
            : movimientos.data
              ? [movimientos.data]
              : [],
        });
      }


      // ======================================================
      // ACCIÓN: DOCUMENTOS DEL MOVIMIENTO
      //
      // Seguridad:
      // - Requiere una sesión vigente.
      // - El token se obtiene EXCLUSIVAMENTE de X-Club-Session.
      // - La identidad del socio sale EXCLUSIVAMENTE de la sesión.
      // - El navegador sólo indica el movimiento a consultar.
      // - La publicación, el nivel y el ocultamiento se aplican en Supabase.
      // - No se entrega la ubicación interna del archivo.
      // ======================================================

      if (
        accion === "documentos_movimiento"
      ) {

        const token =
          String(
            req.headers.get(
              "x-club-session"
            ) || ""
          ).trim();

        if (!token) {
          return respuesta(
            {
              ok: false,
              mensaje: "Sesión requerida",
            },
            401
          );
        }

        const validar =
          await supabaseAdmin.rpc(
            "validar_sesion_segura_interno",
            {
              p_token: token,
            }
          );

        if (
          validar.error ||
          !validar.data
        ) {
          return respuesta(
            {
              ok: false,
              mensaje: "Sesión inválida, vencida o revocada",
            },
            401
          );
        }

        const numeroSocio =
          Number(
            validar.data
          );

        const movimientoId =
          Number(
            body?.movimiento_id
          );

        if (
          !Number.isInteger(movimientoId) ||
          movimientoId <= 0
        ) {
          return respuesta(
            {
              ok: false,
              mensaje: "movimiento_id inválido",
            },
            400
          );
        }

        const documentos =
          await supabaseAdmin.rpc(
            "consultar_documentos_movimiento_interno",
            {
              p_actor: numeroSocio,
              p_movimiento_id: movimientoId,
            }
          );

        if (documentos.error) {
          throw new Error(
            "No pudieron recuperarse los documentos del movimiento: " +
            documentos.error.message
          );
        }

        const uso =
          await supabaseAdmin.rpc(
            "actualizar_uso_sesion_segura_interno",
            {
              p_token: token,
            }
          );

        if (uso.error) {
          throw new Error(
            "No pudo actualizarse el uso de la sesión"
          );
        }

        return respuesta({
          ok: true,
          accion: "documentos_movimiento",
          movimiento_id: movimientoId,
          documentos: Array.isArray(documentos.data)
            ? documentos.data
            : documentos.data
              ? [documentos.data]
              : [],
        });
      }


      // ======================================================
      // ACCIÓN: LOGOUT
      // ======================================================

      if (
        accion === "logout"
      ) {

        const token =
          obtenerTokenSesion(
            req,
            body
          );


        if (!token) {

          return respuesta(
            {
              ok: false,
              mensaje:
                "Sesión requerida",
            },
            401
          );
        }


        // ----------------------------------------------------
        // Primero validamos para saber
        // que estamos cerrando una sesión vigente.
        // ----------------------------------------------------

        const validar =
          await supabaseAdmin.rpc(
            "validar_sesion_segura_interno",
            {
              p_token:
                token,
            }
          );


        if (validar.error) {

          return respuesta(
            {
              ok: false,
              sesion_cerrada:
                false,
              mensaje:
                "Sesión inválida, vencida o revocada",
            },
            401
          );
        }


        // ----------------------------------------------------
        // Revocar
        // ----------------------------------------------------

        const revocar =
          await supabaseAdmin.rpc(
            "revocar_sesion_segura_interno",
            {
              p_token:
                token,

              p_motivo:
                "cierre_usuario",
            }
          );


        if (revocar.error) {

          throw new Error(
            "No pudo cerrarse la sesión: " +
            revocar.error.message
          );
        }


        return respuesta({
          ok: true,

          accion:
            "logout",

          sesion_cerrada:
            true,
        });
      }


      // ======================================================
      // ACCIÓN DESCONOCIDA
      // ======================================================

      return respuesta(
        {
          ok: false,
          error:
            "Acción inexistente",
        },
        400
      );


    } catch (error) {

      console.error(
        "club-abierto-api:",
        error
      );


      return respuesta(
        {
          ok: false,

          error:
            error instanceof Error
              ? error.message
              : "Error interno",
        },
        500
      );
    }

  }
);

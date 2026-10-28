# Anclaje blockchain de Club Abierto

Arquitectura para más de 200.000 socios sin costo para el votante.

- Cada voto genera una huella SHA-256 privada en Supabase.
- Las huellas se ordenan de forma determinista y se procesan en bloques de hasta 4.096.
- Las raíces parciales forman una raíz Merkle final por cierre de encuesta.
- Polygon recibe una sola transacción por raíz final.
- El contrato no almacena nombres, números de socio, opciones ni ponderaciones.
- La billetera institucional patrocinadora paga el gas.
- Consultar el contrato y verificar comprobantes es gratuito.
- La propiedad del contrato debe transferirse a una multisig institucional antes de producción.

Red inicial: Polygon Amoy (prueba). La migración a Polygon PoS mainnet se realiza sólo después de validar contrato, comprobantes, recuperación y monitoreo.

El contrato es deliberadamente mínimo y no actualizable: una raíz ya registrada no puede sobrescribirse.


## Comunidad Formativa y puesta en producción

Las presentaciones formativas generan eventos criptográficos privados y lotes Merkle. Los RPC de servicio para el trabajador de anclajes sólo los puede ejecutar `service_role`; el esquema `comunidad_formativa` no se expone a clientes. Los datos personales, los relatos y los archivos no se publican en blockchain.

El trabajador reconoce lotes de Comunidad Formativa, auditoría y votaciones, pero consulta el interruptor de producción compartido. La configuración institucional debe permanecer desactivada hasta completar la revisión de producción: habilitarla puede permitir envíos de los tres módulos.

### Requisitos todavía pendientes para Polygon Mainnet

- Configurar en Supabase un endpoint RPC de Polygon Mainnet dedicado en el secreto `POLYGON_RPC_URL` y verificar `chainId=137`.
- Completar la revisión de la cuenta EIP-7702 y de la estrategia de firma institucional.
- Transferir la propiedad del contrato a la multisig institucional mediante la secuencia de aceptación de propiedad del contrato.
- Confirmar que la wallet autorizada como `anchorer` y el mecanismo de firma coinciden. La estrategia institucional registrada prohíbe guardar una clave privada de firma en el trabajador.
- Sólo después de esos controles, activar la configuración de producción con autorización institucional. Esa activación es global para los lotes de auditoría, votos y Comunidad Formativa.

Hasta entonces, el sistema debe informar “hash y lote Merkle preparados; blockchain pendiente de activación institucional”. No se debe presentar un lote como verificado en cadena sin transacción y confirmaciones observables.

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

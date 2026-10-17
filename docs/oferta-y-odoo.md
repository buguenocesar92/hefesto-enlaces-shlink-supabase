# Monetización y traspaso a Odoo
Servicio propuesto: dominio corto por empresa, configuración de campañas, enlaces para materiales QR/NFC, reporte de visitas, capacitación y mantenimiento mensual. Puede complementar KraftDo: el QR/NFC apunta al enlace corto, cuyo destino se administra en Shlink. Esta conexión conceptual no modifica KraftDo ni sus tokens.

Cotizar implementación, dominio, hosting/Supabase, volumen, retención, soporte e informes. No hay facturación recurrente/pagos integrados ni promesa de conversiones. Un clic no demuestra venta ni persona única. El dominio debe quedar bajo control del cliente con renovación documentada.

La plantilla CSV es planificación manual, no un importador. El script campaign_url.py agrega UTM localmente:
```sh
python3 scripts/campaign_url.py https://example.com/catalogo --source instagram --medium social --campaign lanzamiento-2026
```
Usar el resultado como destino al crear el enlace. El script consolida parámetros repetidos; si tu destino depende de parámetros duplicados, preparar esa URL manualmente.

## Odoo
Odoo puede administrar cliente, campaña, cotización y contrato; Shlink mantiene redirecciones y analítica. Migrar físicamente Shlink no implica importar SQL a Odoo. Para pasar a otro acortador conservar dominio y slugs, exportar mediante interfaz/API autorizada y reconstruir reglas equivalentes; conciliar antes de cambiar DNS.

| Dato Shlink | Referencia propuesta en Odoo | Revisión |
|---|---|---|
| Dominio/slug | URL de campaña | No cambiar enlaces impresos |
| Destino y UTM | Campaña/origen/medio | Codificación y parámetros |
| Etiquetas | Etiquetas de marketing | Correspondencia manual |
| Visitas agregadas | Informe/registro auxiliar | Mismo período/UTC y definición |
| Clave API | Gestor de secretos | Nunca nota pública ni campo exportable |

No se incluye conector sincronizado ni acceso directo desde Odoo a tablas de Shlink. Cualquier integración futura debe usar API, credenciales de alcance mínimo, manejo de errores y prueba de rotación. Habilitar solo destinos autorizados y restringir quién crea enlaces; no ofrecer un acortador público anónimo por defecto.

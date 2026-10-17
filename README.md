# Hefesto Enlaces · Shlink + Supabase PostgreSQL
Kit de Shlink 5.1.7 y Shlink Web Client 4.8.1 para enlaces cortos bajo dominio propio. Backend PostgreSQL de Supabase dedicado, conexión TLS verify-full, claves API, estadísticas básicas, scripts de respaldo/restauración y guías para Coolify y traspaso.

Funciones nativas: crear/editar destinos, slugs personalizados, etiquetas, condiciones de vigencia según interfaz/API y estadísticas de visitas. Puedes imprimir un QR que contenga el enlace corto y después cambiar su destino. El QR se genera con tu herramienta de diseño/QR (por ejemplo el flujo KraftDo); no se incluye un generador QR propio ni se depende del antiguo endpoint QR de Shlink, deprecado desde 4.5.

## Inicio
Requisitos: Docker + Compose v2, Python 3.11+, VPS con salida PostgreSQL/TLS, dos dominios, proyecto Supabase exclusivo con PostgreSQL 16/17 y certificado CA válido. No requiere Supabase Auth ni Storage.
```sh
python3 scripts/configure.py cliente-demo go.tudominio.cl enlaces.tudominio.cl
```
Completar docs/supabase.md antes de arrancar. Después:
```sh
docker compose -f compose.yaml -f compose.bootstrap.yaml up -d --build
```
Abrir túneles desde tu computador:
```sh
ssh -L 8092:127.0.0.1:8092 -L 8093:127.0.0.1:8093 usuario@servidor
```
Abrir http://localhost:8093, agregar servidor http://localhost:8092 y la INITIAL_API_KEY de .env. Los enlaces generados usarán go.tudominio.cl; solo resolverán públicamente al configurar DNS/HTTPS. Seguir docs/despliegue.md para retirar bootstrap y publicar.

## Alcance de la validación
Compatibilidad PostgreSQL y configuración TLS revisadas contra documentación/código upstream. No se ha conectado a un proyecto Supabase real, construido la imagen ni probado redirecciones/estadísticas en VPS. El kit no está desplegado y la aceptación sigue pendiente.

Este es un paquete de configuración del software nativo, no un SaaS comercial completo con suscripciones, login compartido o cobros. No se incluyen cuentas Supabase, claves reales, geolocalización MaxMind, conectores Odoo/n8n ni envío de campañas. La imagen derivada solo incorpora verificación TLS y un chequeo previo.

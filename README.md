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

## Despliegue en Coolify (MVP Hefesto)
Coolify importa este directorio como Compose, construye el Dockerfile y enruta los dominios vía Traefik. El compose se mantiene sin `ports:`, `container_name:`, `privileged:`, ni binds fuera del repo: el enrutamiento es solo del proxy. Para auditarlo antes de desplegar: `bash scripts/coolify-check.sh`.

Variables adicionales (todas con default funcional para no romper el uso original):

| Variable | Default | Para qué sirve en Coolify |
|---|---|---|
| `DB_NAME` | `postgres` | Nombre de la base dedicada (`mvp_<slug>`) en el Postgres compartido. |
| `DB_SSLMODE` | `verify-full` | Relaja TLS cuando la red interna de Coolify no exige verificar CA (`disable` para localhost/VPN, `require` para redis/pooler sin CA propia). |
| `DB_SSLROOTCERT` | `/run/supabase/ca.crt` | Ruta del CA. Solo se exige cuando `DB_SSLMODE=verify-full`; en cualquier otro modo `certs/ca.crt` puede omitirse. |
| `INITIAL_API_KEY` | _(vacío)_ | Si está vacío, genera la primera clave con `shlink api-key:generate` dentro del contenedor y guárdala en un gestor antes de retirar el bootstrap. Si trae valor, Shlink la usa como clave inicial. |
| `TRUSTED_PROXIES` | `127.0.0.1` | Cambia al CIDR de la red de Traefik en Coolify (p. ej. `172.16.0.0/12`) para que Shlink preserve `X-Forwarded-For`. |

Notas: `compose.bootstrap.yaml` es override de desarrollo local (SSH + puertos 8092/8093); no lo apliques en Coolify. Las preflights que exigen proyecto dedicado (`SUPABASE_DEDICATED_CONFIRMED=true`) y Data API apagada (`SUPABASE_DATA_API_DISABLED=true`) se mantienen; configura ambas en `true` en Coolify cuando termines los pasos de `docs/supabase.md`.

Pasos operativos de la base dedicada:

1. Crea la base de datos con el mismo slug del proyecto Coolify, por ejemplo `mvp_coolify`, conectada al Postgres compartido de Supabase (no a la base `postgres`).
2. `POSTGRES_USERNAME` debe corresponder al rol `shlink_app` (es lo que `ops/preflight.sql` y `ops/check-config.php` validan).
3. Ejecuta `sql/01-supabase-app.sql` **en esa base** (`psql ... -d mvp_<slug>`). El script está escrito contra `DATABASE postgres`; reemplaza las dos ocurrencias de `postgres` por `$DB_NAME` (`mvp_<slug>`) en `sql/01-supabase-app.sql:11` (`GRANT CONNECT ON DATABASE postgres`) y en `sql/01-supabase-app.sql:13` (`ALTER ROLE shlink_app IN DATABASE postgres SET search_path`). El resto del script es por esquema `public` y no depende del nombre de la base.
4. Después de aplicarlo, fija `DB_NAME=mvp_<slug>` en las variables de Coolify y mantén `DB_SSLMODE=verify-full` salvo que la red interna no entregue CA propia (en ese caso, `DB_SSLMODE=require` o `disable` y deja `DB_SSLROOTCERT` con el default del kit).

## Alcance de la validación
Compatibilidad PostgreSQL y configuración TLS revisadas contra documentación/código upstream. No se ha conectado a un proyecto Supabase real, construido la imagen ni probado redirecciones/estadísticas en VPS. El kit no está desplegado y la aceptación sigue pendiente.

Este es un paquete de configuración del software nativo, no un SaaS comercial completo con suscripciones, login compartido o cobros. No se incluyen cuentas Supabase, claves reales, geolocalización MaxMind, conectores Odoo/n8n ni envío de campañas. La imagen derivada solo incorpora verificación TLS y un chequeo previo.

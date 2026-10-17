# Backup, recuperación y traspaso
## Backup
```sh
python3 scripts/backup.py
```
Usar el contexto Compose real del recurso. Detiene app para pausar escrituras y realiza pg_dump de public (custom, sin propietarios/ACL). Reinicia app incluso ante fallo. Escribe manifest completed solo al completar. Copia .env y Compose: contiene claves. Cifrar y copiar fuera del VPS junto con este kit y CA; no se ha instalado cron/retención/repo externo.

La base contiene enlaces, dominios, visitas y claves API. No hay adjuntos de negocio locales: data/cache/proxies/locks se recrean y la geolocalización está desactivada. No montar un volumen antiguo de caché al actualizar. El panel guarda configuración en cada navegador; ese dato no está en el dump. Conservar claves necesarias en un gestor separado. Un backup no garantiza que se hayan persistido tareas pendientes de visitas: comprobar colas y detener actividad en la ventana de mantenimiento.

## Restaurar a otro proyecto dedicado
1. Crear destino nuevo con PostgreSQL compatible y repetir preparación de rol/CA. Usar el ZIP de la misma versión. No reutilizar el proyecto de origen.
2. Configurar .env destino con host/usuario/clave nuevos, dominios de ensayo y COMPOSE_PROJECT_NAME nuevo. No arrancar Shlink antes de restaurar; crearía tablas.
3. Ejecutar `docker compose run --rm preflight` y `python3 scripts/restore_db.py /ruta/backup`. El script comprueba versión/hash del dump y que public no tenga tablas; restaura objetos como shlink_app, sin DROP ni ACL. Excluye la creación del esquema public porque Supabase ya lo tiene. No recupera esquemas internos auth/storage ni usuarios Supabase.
4. Si la restauración falla parcialmente, usar un nuevo destino vacío; no borrar automáticamente objetos. Arrancar app/panel y verificar claves, dominios, slugs, destinos, conteos y redirecciones.
5. Antes de corte final: pausar creación/edición y visitas según ventana, último backup, restauración final en destino nuevo, verificación y cambio DNS. Conservar dominio corto es esencial para los QR/enlaces existentes. Registrar A/AAAA/TLS y conservar propiedad/renovación del dominio.

## Actualización
Ensayar imagen/tag/digest nuevos en clon restaurado. Verificar override TLS con la versión de Doctrine y salud antes de cambiar producción. Rollback mediante versión y backup compatibles; no bajar imagen sobre esquema migrado. Registrar digest de postgres:17-alpine usado por herramientas y actualizarlo deliberadamente.

## Entrega
Entregar kit, proyecto Supabase, rol/clave en gestor, CA, dominios/DNS, configuración Coolify, claves API con alcances, respaldos cifrados, versiones y prueba de restauración. No guardar API keys en archivos estáticos del panel. Reconfigurar el navegador del nuevo operador y revocar claves del proveedor saliente tras aceptación.

# Validación realizada

Revisión estática de YAML/Python/shell, aislamiento de puertos, TLS verify-full, configuración del panel sin API keys públicas, imagen/digest, generación de .env con permisos 0600 y rechazo de sobrescritura. Probado el constructor UTM con consulta y fragmento. Integridad del ZIP comprobada y sin secretos/certificados reales.

Código upstream revisado: soporte PostgreSQL, Doctrine PDO 4.4 con sslmode/sslrootcert a nivel conexión, orden de carga de archivos global.php y arranque del instalador. Compatibilidad inferida de documentación/código, no certificada mediante conexión a Supabase.

Pendiente: PHP lint, docker compose config/build, conexión TLS real directa/Session pooler, SQL de permisos, migraciones, claves API, redirecciones, interfaz, estadísticas y backup/restore en destino vacío. No hay Docker/PHP disponibles aquí. Completar docs/aceptacion.md.

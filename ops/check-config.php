<?php
declare(strict_types=1);
chdir('/etc/shlink');
require 'vendor/autoload.php';
try {
    $config = require 'config/config.php';
    $p = $config['entity_manager']['connection'];
    if (($p['driver'] ?? '') !== 'pdo_pgsql') {
        throw new RuntimeException('Falta configuración PostgreSQL');
    }
    // Allowlist cerrada: nada de sslmode arbitrario desde env o config.
    $sslModes = ['disable', 'allow', 'prefer', 'require', 'verify-ca', 'verify-full'];
    $sslmode = $p['sslmode'] ?? 'verify-full';
    if (!in_array($sslmode, $sslModes, true)) {
        throw new RuntimeException('sslmode invalido: '.$sslmode);
    }
    $sslrootcert = $p['sslrootcert'] ?? '/run/supabase/ca.crt';
    // Whitelist de rutas para sslrootcert: solo el default del kit o /run/supabase/* o /etc/ssl/certs/*.
    $rootOk = ($sslrootcert === '/run/supabase/ca.crt')
        || str_starts_with($sslrootcert, '/run/supabase/')
        || str_starts_with($sslrootcert, '/etc/ssl/certs/');
    if (!$rootOk) {
        throw new RuntimeException('sslrootcert fuera de rutas permitidas: '.$sslrootcert);
    }
    // CA legible solo exigida cuando el modo verifica el certificado del servidor.
    if (in_array($sslmode, ['verify-full', 'verify-ca'], true) && !is_readable($sslrootcert)) {
        throw new RuntimeException('Falta configuración PostgreSQL/TLS');
    }
    foreach (['host','dbname'] as $k) {
        if (!preg_match('/^[a-zA-Z0-9_.-]+$/', (string)$p[$k])) throw new RuntimeException('Parámetro DB inválido');
    }
    // DSN: omitir sslrootcert cuando sslmode=disable; rechazar cualquier intento de
    // inyectar caracteres de control o '=' fuera del lugar esperado.
    foreach ([$p['host'], $p['dbname'], $sslmode, $sslrootcert] as $part) {
        if (!preg_match('/^[A-Za-z0-9._\/\-]+$/', (string)$part)) {
            throw new RuntimeException('Parámetro DB con caracteres no permitidos');
        }
    }
    $dsn = 'pgsql:host='.$p['host'].';port=5432;dbname='.$p['dbname'].';sslmode='.$sslmode;
    if ($sslmode !== 'disable') {
        $dsn .= ';sslrootcert='.$sslrootcert;
    }
    $db = new PDO($dsn, $p['user'], $p['password'], [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
    if ($db->query('SELECT current_user')->fetchColumn() !== 'shlink_app') throw new RuntimeException('Rol no autorizado');
    // TLS verificable solo si sslmode lo negocia; con disable no se exige.
    if ($sslmode !== 'disable' && !$db->query('SELECT ssl FROM pg_stat_ssl WHERE pid=pg_backend_pid()')->fetchColumn()) {
        throw new RuntimeException('Conexión sin TLS');
    }
    echo "Configuración y conexión PHP/TLS verificadas\n";
} catch (Throwable $e) {
    // Do not print connection strings or credentials in startup logs.
    fwrite(STDERR, "Preflight PHP falló. Revisar rol, CA, host y conexión; no se inicia Shlink.\n");
    exit(1);
}

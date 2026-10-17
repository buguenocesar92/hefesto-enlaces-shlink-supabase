<?php
declare(strict_types=1);
chdir('/etc/shlink');
require 'vendor/autoload.php';
try {
    $config = require 'config/config.php';
    $p = $config['entity_manager']['connection'];
    if (($p['driver'] ?? '') !== 'pdo_pgsql' || ($p['sslmode'] ?? '') !== 'verify-full'
        || ($p['sslrootcert'] ?? '') !== '/run/supabase/ca.crt' || !is_readable($p['sslrootcert'])) {
        throw new RuntimeException('Falta configuración PostgreSQL/TLS');
    }
    foreach (['host','dbname'] as $k) {
        if (!preg_match('/^[a-zA-Z0-9_.-]+$/', (string)$p[$k])) throw new RuntimeException('Parámetro DB inválido');
    }
    $dsn = 'pgsql:host='.$p['host'].';port=5432;dbname='.$p['dbname'].';sslmode=verify-full;sslrootcert='.$p['sslrootcert'];
    $db = new PDO($dsn, $p['user'], $p['password'], [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
    if ($db->query('SELECT current_user')->fetchColumn() !== 'shlink_app') throw new RuntimeException('Rol no autorizado');
    if (!$db->query('SELECT ssl FROM pg_stat_ssl WHERE pid=pg_backend_pid()')->fetchColumn()) throw new RuntimeException('Conexión sin TLS');
    echo "Configuración y conexión PHP/TLS verificadas\n";
} catch (Throwable $e) {
    // Do not print connection strings or credentials in startup logs.
    fwrite(STDERR, "Preflight PHP falló. Revisar rol, CA, host y conexión; no se inicia Shlink.\n");
    exit(1);
}

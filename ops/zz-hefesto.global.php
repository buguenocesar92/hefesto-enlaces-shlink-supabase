<?php
declare(strict_types=1);
// Loaded after entity-manager.global.php. DBAL PDO pgsql reads TLS parameters at connection level.
// Por defecto verify-full + la CA del kit; el operador puede relajar via DB_SSLMODE / DB_SSLROOTCERT
// (util cuando Supabase comparte cluster y la red interna no exige verificar certificado).

// Allowlist cerrada: cualquier valor fuera de este conjunto aborta el arranque para
// evitar que un operador o un secreto mal formado baje el TLS en silencio.
$sslModes = ['disable', 'allow', 'prefer', 'require', 'verify-ca', 'verify-full'];
$sslModeEnv = getenv('DB_SSLMODE');
$sslMode = ($sslModeEnv === false || $sslModeEnv === '') ? 'verify-full' : $sslModeEnv;
if (!in_array($sslMode, $sslModes, true)) {
    throw new RuntimeException('DB_SSLMODE invalido: '.$sslMode.' (permitidos: '.implode(',', $sslModes).')');
}

// Whitelist de rutas para el certificado: solo se acepta el default del kit o
// rutas dentro de /run/supabase o /etc/ssl/certs; cualquier otra cosa se rechaza.
$allowedRoots = ['/run/supabase/', '/etc/ssl/certs/'];
$sslRootCertEnv = getenv('DB_SSLROOTCERT');
$sslRootCert = ($sslRootCertEnv === false || $sslRootCertEnv === '') ? '/run/supabase/ca.crt' : $sslRootCertEnv;
$rootOk = ($sslRootCert === '/run/supabase/ca.crt')
    || array_filter($allowedRoots, static fn(string $r): bool => str_starts_with($sslRootCert, $r)) !== [];
if (!$rootOk) {
    throw new RuntimeException('DB_SSLROOTCERT invalido: '.$sslRootCert.' (permitidos: '.implode(', ', $allowedRoots).') o el default /run/supabase/ca.crt');
}

return ['entity_manager' => ['connection' => [
    'sslmode' => $sslMode,
    'sslrootcert' => $sslRootCert,
]]];

<?php
declare(strict_types=1);
// Loaded after entity-manager.global.php. DBAL PDO pgsql reads TLS parameters at connection level.
// Por defecto verify-full + la CA del kit; el operador puede relajar via DB_SSLMODE / DB_SSLROOTCERT
// (util cuando Supabase comparte cluster y la red interna no exige verificar certificado).
$sslmode = getenv('DB_SSLMODE');
$sslrootcert = getenv('DB_SSLROOTCERT');
return ['entity_manager' => ['connection' => [
    'sslmode' => ($sslmode === false || $sslmode === '') ? 'verify-full' : $sslmode,
    'sslrootcert' => ($sslrootcert === false || $sslrootcert === '') ? '/run/supabase/ca.crt' : $sslrootcert,
]]];

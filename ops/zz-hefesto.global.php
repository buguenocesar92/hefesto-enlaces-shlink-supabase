<?php
declare(strict_types=1);
// Loaded after entity-manager.global.php. DBAL PDO pgsql reads TLS parameters at connection level.
return ['entity_manager' => ['connection' => [
    'sslmode' => 'verify-full',
    'sslrootcert' => '/run/supabase/ca.crt',
]]];

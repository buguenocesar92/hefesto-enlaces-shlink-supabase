#!/bin/sh
set -eu
cd /etc/shlink
mkdir -p data/cache data/locks data/log data/proxies data/temp-geolite
php /opt/hefesto/check-config.php
exec /bin/sh ./docker-entrypoint.sh

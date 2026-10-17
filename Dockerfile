FROM shlinkio/shlink:5.1.7@sha256:844e1f2b6455331c5b49207bad3a2455ccd65e62bb9daa09a6c57afff26bd9c8
COPY ops/zz-hefesto.global.php /etc/shlink/config/autoload/zz-hefesto.global.php
COPY ops/check-config.php /opt/hefesto/check-config.php
COPY --chmod=755 ops/start.sh /opt/hefesto/start.sh
ENTRYPOINT ["/bin/sh", "/opt/hefesto/start.sh"]

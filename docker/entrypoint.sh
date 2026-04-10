#!/bin/sh
set -e
ROOT=/var/www/html
DEF=/opt/perfex-volume-defaults

# Named volumes mount over image directories. New volumes start empty, which
# hides baked-in files and breaks the app. Copy defaults only when markers are missing.
seed_if_missing() {
  target="$1"
  rel="$2"
  marker="$3"
  if [ ! -e "$target/$marker" ]; then
    echo "perfex-docker: seeding $target (missing $marker)"
    mkdir -p "$target"
    cp -a "$DEF/$rel"/. "$target"/
  fi
}

seed_if_missing "$ROOT/application/config" "application/config" "config.php"
seed_if_missing "$ROOT/uploads" "uploads" "index.html"
seed_if_missing "$ROOT/application/cache" "application/cache" "index.html"
seed_if_missing "$ROOT/temp" "temp" "index.html"
seed_if_missing "$ROOT/application/logs" "application/logs" "index.html"

# In Docker Compose, MySQL is another service (e.g. hostname "db"), not localhost.
if [ -n "${APP_DB_HOSTNAME:-}" ] && [ -f "$ROOT/application/config/app-config.php" ]; then
  sed -i "s/define('APP_DB_HOSTNAME', '[^']*')/define('APP_DB_HOSTNAME', '${APP_DB_HOSTNAME}')/" \
    "$ROOT/application/config/app-config.php"
fi

exec apache2-foreground "$@"

#!/usr/bin/env bash
# scripts/test-coolify-check-binds.sh
# Tests unitarios de la regla de binds de scripts/coolify-check.sh.
# Demuestra que la regla acepta binds dentro del repo o al propio repo root
# y rechaza binds fuera del repo o a /var/run/docker.sock.
#
# Ejecutar con: bash scripts/test-coolify-check-binds.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source el validador (source-guard evita que main() se ejecute al cargar).
# shellcheck source=coolify-check.sh
source "$SCRIPT_DIR/coolify-check.sh"

assert_empty() {
    local got="$1" msg="$2"
    if [[ -n "$got" ]]; then
        echo "FAIL: $msg"
        echo "  esperado: vacío"
        echo "  recibido: $got"
        exit 1
    fi
}

assert_contains() {
    local got="$1" needle="$2" msg="$3"
    if ! grep -qF "$needle" <<<"$got"; then
        echo "FAIL: $msg"
        echo "  esperado contiene: $needle"
        echo "  recibido: $got"
        exit 1
    fi
}

# Caso 1 (bug): bind igual al repo root (ej. .:/app que resuelve a REPO_ROOT).
# Antes del fix la regla lo marca como bind-fuera-del-repo y falla.
JSON1="$(jq -n --arg repo "$REPO_ROOT" '
    {services: {app: {volumes: [
        {type: "bind", source: $repo, target: "/app", bind: {}}
    ]}}}
')"
out1="$(bind_violations "$JSON1")"
assert_empty "$out1" "bind = REPO_ROOT debe aceptarse (era el bug)"

# Caso 2: bind dentro del repo (subdirectorio). Debe aceptarse.
JSON2="$(jq -n --arg repo "$REPO_ROOT" '
    {services: {app: {volumes: [
        {type: "bind", source: ($repo + "/certs"), target: "/run/supabase", bind: {}}
    ]}}}
')"
out2="$(bind_violations "$JSON2")"
assert_empty "$out2" "bind dentro del repo debe aceptarse"

# Caso 3: bind fuera del repo (path absoluto ajeno). Debe rechazarse.
JSON3="$(jq -n --arg repo "$REPO_ROOT" '
    {services: {app: {volumes: [
        {type: "bind", source: "/etc/passwd", target: "/app", bind: {}}
    ]}}}
')"
out3="$(bind_violations "$JSON3")"
assert_contains "$out3" "app" "bind fuera del repo debe rechazarse"

# Caso 4: bind a /var/run/docker.sock. Debe rechazarse.
JSON4="$(jq -n --arg repo "$REPO_ROOT" '
    {services: {app: {volumes: [
        {type: "bind", source: "/var/run/docker.sock", target: "/var/run/docker.sock", bind: {}}
    ]}}}
')"
out4="$(bind_violations "$JSON4")"
assert_contains "$out4" "app" "bind a docker.sock debe rechazarse"

# Caso 5: bind con prefijo comun pero fuera del repo (hermano).
# 'hefesto-enlaces-shlink-supabase-otro' empieza por el mismo prefijo
# pero NO es un subdirectorio del repo. Antes del fix el startswith se
# confundia con este caso.
JSON5="$(jq -n --arg repo "$REPO_ROOT" '
    {services: {app: {volumes: [
        {type: "bind", source: ($repo + "-otro"), target: "/app", bind: {}}
    ]}}}
')"
out5="$(bind_violations "$JSON5")"
assert_contains "$out5" "app" "bind con prefijo comun pero fuera del repo debe rechazarse"

# Caso 6: servicio dentro de 'profiles' no se inspecciona (debe aceptarse).
JSON6="$(jq -n --arg repo "$REPO_ROOT" '
    {services: {app: {
        profiles: ["x"],
        volumes: [
            {type: "bind", source: "/etc/passwd", target: "/app", bind: {}}
        ]
    }}}
')"
out6="$(bind_violations "$JSON6")"
assert_empty "$out6" "bind en servicio con profiles no se inspecciona"

# Caso 7: bind corto relativo (./certs) no es path absoluto, se acepta.
JSON7="$(jq -n --arg repo "$REPO_ROOT" '
    {services: {app: {volumes: [
        "./certs:/run/supabase:ro"
    ]}}}
')"
out7="$(bind_violations "$JSON7")"
assert_empty "$out7" "bind corto relativo debe aceptarse"

echo "OK: bind_violations acepta repo-root y subdir, rechaza fuera y docker.sock"
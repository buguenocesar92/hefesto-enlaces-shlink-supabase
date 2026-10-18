#!/usr/bin/env bash
# scripts/coolify-check.sh
# Auditoría estática del/los compose declarados contra el contrato Coolify del proyecto.
# Renderiza cada compose con un .env ficticio (no secretos) y revisa el JSON resultante con jq.
# Sale con 0 si todo cumple, 1 si alguna regla falla (con mensaje "FAIL servicio: motivo").
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Compose que Coolify desplegaría. compose.bootstrap.yaml es override de desarrollo local
# y queda fuera de este chequeo (ver docs/despliegue.md).
COMPOSE_FILES=("$REPO_ROOT/compose.yaml")

URL_PLACEHOLDER='https://ejemplo.invalid'
FAKE_PLACEHOLDER='x123abcdef'

# Variables adicionales específicas del kit. Para bases compartidas en Supabase
# (apps 'bd: supabase-pg') la base dedicada y el sslmode deben ser parametrizables.
extra_vars_for() {
    case "$(basename "$1")" in
        compose.yaml) printf 'DB_NAME=mvp_prueba\nDB_SSLMODE=disable\n' ;;
        *) ;;
    esac
}

# Nombres de variables referenciadas por el compose (forma ${VAR}, ${VAR:?...}, ${VAR:-...}).
# La regex permite todo lo no-} entre el identificador y el cierre; luego se descarta el sufijo ":?..."/"...".
extract_vars() {
    grep -oE '\$\{[A-Za-z_][A-Za-z0-9_]*[^{}]*\}' "$1" \
        | sed -E 's/^\$\{//; s/\}$//; s/:.*$//' \
        | sort -u
}

# Cualquier variable de host o URL toma un placeholder URL; el resto, un placeholder opaco.
is_host_var() {
    case "$1" in
        POSTGRES_HOST|LINKS_HOST|PANEL_HOST|*_HOST|*_URL) return 0 ;;
        *) return 1 ;;
    esac
}

write_envfile() {
    local compose="$1" envfile="$2"
    : > "$envfile"
    local vars
    vars="$(extract_vars "$compose")"
    while IFS= read -r v; do
        [[ -z "$v" ]] && continue
        if is_host_var "$v"; then
            printf '%s=%s\n' "$v" "$URL_PLACEHOLDER" >> "$envfile"
        else
            printf '%s=%s\n' "$v" "$FAKE_PLACEHOLDER" >> "$envfile"
        fi
    done <<<"$vars"
    while IFS= read -r kv; do
        [[ -z "$kv" ]] && continue
        local k="${kv%%=*}"
        sed -i "/^${k}=/d" "$envfile" 2>/dev/null || true
        printf '%s\n' "$kv" >> "$envfile"
    done <<<"$(extra_vars_for "$compose")"
}

render() {
    docker compose --project-directory "$REPO_ROOT" -f "$1" \
        --env-file "$2" config --format json
}

# Reglas del contrato 1 (escape al host) y 2 (nombres estables sin forzar).
validate_contract() {
    local label="$1" json="$2" compose="$3"
    local rc=0

    # 1. Raíz sin 'name:' fijo explicit. Sin declaracion, docker compose deriva del directorio y Coolify sobreescribe.
    if grep -qE '^name[[:space:]]*:' "$compose"; then
        echo "FAIL ${label}: raiz declara 'name:' fijo en compose.yaml; Coolify asigna el nombre del proyecto"
        rc=1
    fi

    # 2. Servicios sin 'profiles': nada que escape al host ni dé poder sobre él.
    local violations
    violations="$(printf '%s' "$json" | jq -r --arg repo "$REPO_ROOT" '
        (.services // {}) as $services
        | $services | to_entries
        | map(select((.value.profiles // []) | length == 0))
        | .[]
        | .key as $svc
        | .value
        | (
            (((.ports // []) | length) > 0) | if . then "ports" else empty end),
            (has("container_name") | if . then "container_name" else empty end),
            (((.privileged // false)) | if . then "privileged" else empty end),
            (((.cap_add // []) | length) > 0 | if . then "cap_add" else empty end),
            (((.devices // []) | length) > 0 | if . then "devices" else empty end),
            (((.network_mode // "") == "host") | if . then "network_mode=host" else empty end),
            (((.pid // "") == "host") | if . then "pid=host" else empty end),
            (((.ipc // "") == "host") | if . then "ipc=host" else empty end),
            (((.security_opt // []) | any(test("unconfined"))) | if . then "security_opt=unconfined" else empty end),
            ((.volumes // []) | map(
                if type == "string" then split(":")[0]
                elif type == "object" then (.source // "")
                else "" end
                | select(. != "" and (
                    test("^/var/run/docker\\.sock")
                    or (test("^/") and (. != $repo and (. | startswith($repo + "/")) | not))
                ))
            ) | if length > 0 then "bind-fuera-del-repo-o-docker.sock" else empty end)
        | "\($svc):\(.)"
    ')"
    while IFS= read -r v; do
        [[ -z "$v" ]] && continue
        echo "FAIL ${label}: servicio '${v%%:*}' declara '${v##*:}'; vetado por el contrato Coolify"
        rc=1
    done <<<"$violations"

    # 3. Volúmenes top-level sin 'name:' fijo.
    local fixed_vols
    fixed_vols="$(printf '%s' "$json" | jq -r '(.volumes // {}) | to_entries | map(select(.value.name != null)) | .[].key' 2>/dev/null || true)"
    while IFS= read -r k; do
        [[ -z "$k" ]] && continue
        echo "FAIL ${label}: volumen '${k}' tiene 'name:' fijo; Coolify asigna el nombre"
        rc=1
    done <<<"$fixed_vols"

    return $rc
}

# Para 'bd: supabase-pg': las variables DB_NAME y DB_SSLMODE deben llegar al servicio web.
validate_supabase_pg() {
    local label="$1" json="$2"
    local rc=0
    local app_env
    app_env="$(printf '%s' "$json" | jq -r '.services.app.environment // {} | to_entries | map("\(.key)=\(.value|tostring)") | .[]' 2>/dev/null || true)"
    if ! grep -q 'DB_NAME=mvp_prueba' <<<"$app_env"; then
        echo "FAIL ${label} (supabase-pg): servicio 'app' no expone DB_NAME=mvp_prueba en environment; falta variable DB_NAME con default postgres"
        rc=1
    fi
    # DB_SSLMODE debe llegar al servicio 'app' como DB_SSLMODE (lo lee ops/zz-hefesto.global.php
    # via getenv()); PGSSLMODE=disable se acepta ademas porque es la copia libpq del mismo valor.
    if ! grep -qE 'DB_SSLMODE=disable' <<<"$app_env"; then
        echo "FAIL ${label} (supabase-pg): servicio 'app' no expone DB_SSLMODE=disable; PHP no ve la variable si solo llega como PGSSLMODE"
        rc=1
    fi
    if ! grep -qE 'PGSSLMODE=disable' <<<"$app_env"; then
        echo "FAIL ${label} (supabase-pg): servicio 'app' no expone PGSSLMODE=disable; libpq no honrara DB_SSLMODE=disable"
        rc=1
    fi
    return $rc
}

main() {
    local rc=0
    for compose in "${COMPOSE_FILES[@]}"; do
        if [[ ! -f "$compose" ]]; then
            echo "FAIL: no existe $compose"
            rc=1
            continue
        fi
        local label
        label="$(basename "$compose")"
        local envfile
        envfile="$(mktemp)"
        write_envfile "$compose" "$envfile"
        local output
        # Captura stdout+stderr; `|| true` neutraliza `set -e` para que podamos inspeccionar.
        output="$(render "$compose" "$envfile" 2>&1)" || true
        rm -f "$envfile"
        # docker emite avisos (config, deprecation) a STDERR; al fusionar 2>&1 se mezclan
        # con el JSON. Recortamos a partir del primer '{' para que jq valide el cuerpo.
        local json
        json="$(printf '%s' "$output" | sed -n '/^{/,$p')"
        if [[ -z "$json" ]] || ! printf '%s' "$json" | jq . >/dev/null 2>&1; then
            echo "FAIL ${label}: docker compose config no pudo renderizar:"
            sed 's/^/    /' <<<"$output"
            rc=1
            continue
        fi
        if ! validate_contract "$label" "$json" "$compose"; then
            rc=1
        fi
        if ! validate_supabase_pg "$label" "$json"; then
            rc=1
        fi
    done

    if [[ "$rc" -ne 0 ]]; then
        exit 1
    fi
    echo "OK: compose Coolify-ready"
}

main "$@"

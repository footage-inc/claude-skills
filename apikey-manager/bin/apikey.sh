#!/usr/bin/env bash
set -euo pipefail

# --store <path> オプションでストアのディレクトリを変更可能
# 未指定時は ~/.claude/apikeys をデフォルトで使用
STORE_DIR="$HOME/.claude/apikeys"

# --store パースを先に行う
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --store)
      STORE_DIR="$2"
      shift 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done
set -- "${ARGS[@]}"

STORE_FILE="$STORE_DIR/store.enc"
OPENSSL_OPTS="-aes-256-cbc -pbkdf2 -iter 100000"

usage() {
  cat <<'EOF'
Usage: apikey.sh [--store <dir>] <command> [args...]

Options:
  --store <dir>              Store directory (default: ~/.claude/apikeys)
                             Use for project-level shared stores

Commands:
  init                       Initialize empty encrypted store
  decrypt <password>         Decrypt store and output JSON to stdout
  encrypt <password>         Read JSON from stdin and encrypt to store
  list <password>            List all keys (masked values)
  get <password> <svc> [env] Get a specific key value
  set <password> <json>      Set full store from JSON string
  merge <password> <json>    Merge keys from JSON into existing store
EOF
  exit 1
}

ensure_deps() {
  for cmd in openssl jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "Error: $cmd is required but not installed." >&2
      exit 1
    fi
  done
}

init_store() {
  local pw="$1"
  mkdir -p "$STORE_DIR"
  if [[ -f "$STORE_FILE" ]]; then
    echo "Store already exists at $STORE_FILE"
    exit 0
  fi
  echo '{"keys":{},"projects":{}}' | openssl enc $OPENSSL_OPTS -salt -pass "pass:$pw" -out "$STORE_FILE"
  echo "Store initialized at $STORE_FILE"
}

decrypt_store() {
  local pw="$1"
  if [[ ! -f "$STORE_FILE" ]]; then
    echo "Error: Store not found. Run 'init' first." >&2
    exit 1
  fi
  openssl enc $OPENSSL_OPTS -d -pass "pass:$pw" -in "$STORE_FILE" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    echo "Error: Decryption failed. Wrong password?" >&2
    exit 1
  fi
}

encrypt_store() {
  local pw="$1"
  mkdir -p "$STORE_DIR"
  local json
  json=$(cat)
  # Validate JSON
  echo "$json" | jq . >/dev/null 2>&1 || { echo "Error: Invalid JSON" >&2; exit 1; }
  echo "$json" | openssl enc $OPENSSL_OPTS -salt -pass "pass:$pw" -out "$STORE_FILE"
}

mask_value() {
  local val="$1"
  local len=${#val}
  if [[ $len -le 4 ]]; then
    echo "****"
  else
    local suffix="${val: -4}"
    local mask_len=$((len - 4))
    printf '%*s' "$mask_len" '' | tr ' ' '*'
    echo "$suffix"
  fi
}

list_keys() {
  local pw="$1"
  local json
  json=$(decrypt_store "$pw")

  echo "$json" | jq -r '
    .keys | to_entries[] | .key as $svc |
    .value | to_entries[] |
    "\($svc)\t\(.key)\t\(.value.env_var // "-")\t\(.value.value)\t\(.value.added // "-")"
  ' | while IFS=$'\t' read -r svc env env_var val added; do
    masked=$(mask_value "$val")
    printf "%-15s %-10s %-25s %-20s %s\n" "$svc" "$env" "$env_var" "$masked" "$added"
  done
}

get_key() {
  local pw="$1"
  local svc="$2"
  local env="${3:-default}"
  local json
  json=$(decrypt_store "$pw")

  local result
  result=$(echo "$json" | jq -r --arg svc "$svc" --arg env "$env" '.keys[$svc][$env].value // empty')

  if [[ -z "$result" ]]; then
    echo "Error: Key not found for service='$svc' env='$env'" >&2
    exit 1
  fi
  echo "$result"
}

set_store() {
  local pw="$1"
  local json="$2"
  echo "$json" | jq . >/dev/null 2>&1 || { echo "Error: Invalid JSON" >&2; exit 1; }
  echo "$json" | openssl enc $OPENSSL_OPTS -salt -pass "pass:$pw" -out "$STORE_FILE"
}

merge_store() {
  local pw="$1"
  local new_json="$2"
  echo "$new_json" | jq . >/dev/null 2>&1 || { echo "Error: Invalid JSON" >&2; exit 1; }

  local current
  if [[ -f "$STORE_FILE" ]]; then
    current=$(decrypt_store "$pw")
  else
    current='{"keys":{},"projects":{}}'
  fi

  # deep merge: 既存キーは上書きしない（新規キーのみ追加）
  local merged
  merged=$(echo "$current" | jq --argjson new "$new_json" '
    .keys = ($new.keys // {}) * .keys |
    .projects = ($new.projects // {}) * .projects
  ')
  mkdir -p "$STORE_DIR"
  echo "$merged" | openssl enc $OPENSSL_OPTS -salt -pass "pass:$pw" -out "$STORE_FILE"
  echo "Merged successfully."
}

# --- Main ---
ensure_deps

cmd="${1:-}"
shift || true

case "$cmd" in
  init)
    [[ $# -lt 1 ]] && { echo "Usage: apikey.sh init <password>" >&2; exit 1; }
    init_store "$1"
    ;;
  decrypt)
    [[ $# -lt 1 ]] && { echo "Usage: apikey.sh decrypt <password>" >&2; exit 1; }
    decrypt_store "$1"
    ;;
  encrypt)
    [[ $# -lt 1 ]] && { echo "Usage: apikey.sh encrypt <password>" >&2; exit 1; }
    encrypt_store "$1"
    ;;
  list)
    [[ $# -lt 1 ]] && { echo "Usage: apikey.sh list <password>" >&2; exit 1; }
    list_keys "$1"
    ;;
  get)
    [[ $# -lt 2 ]] && { echo "Usage: apikey.sh get <password> <service> [env]" >&2; exit 1; }
    get_key "$1" "$2" "${3:-default}"
    ;;
  set)
    [[ $# -lt 2 ]] && { echo "Usage: apikey.sh set <password> <json>" >&2; exit 1; }
    set_store "$1" "$2"
    ;;
  merge)
    [[ $# -lt 2 ]] && { echo "Usage: apikey.sh merge <password> <json>" >&2; exit 1; }
    merge_store "$1" "$2"
    ;;
  *)
    usage
    ;;
esac

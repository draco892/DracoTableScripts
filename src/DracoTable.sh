#!/bin/bash

set -u
set -o pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${BASE_DIR}/conf"
CONFIG_FILE="${CONFIG_DIR}/DracoTable.conf"

log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

fail() {
    local msg="$1"
    echo "ERROR: $msg" >&2
    osascript -e 'display dialog "DracoTable launch failed:\n'"$msg"'" buttons {"OK"} default button "OK" with icon stop'
    exit 1
}

notify() {
    local msg="$1"
    osascript -e 'display notification "'"$msg"'" with title "DracoTable"'
}

require_var() {
    local var_name="$1"
    local var_value="${!var_name:-}"

    if [ -z "$var_value" ]; then
        fail "Missing or empty required configuration field: $var_name"
    fi
}

log "Starting DracoTable launcher"

[ -d "$SCRIPT_DIR" ] || fail "Script directory not found: $SCRIPT_DIR"
[ -d "$BASE_DIR" ] || fail "Base directory not found: $BASE_DIR"
[ -d "$CONFIG_DIR" ] || fail "Configuration directory not found: $CONFIG_DIR"
[ -e "$CONFIG_FILE" ] || fail "Configuration file not found: $CONFIG_FILE"
[ -f "$CONFIG_FILE" ] || fail "Configuration path is not a regular file: $CONFIG_FILE"
[ -r "$CONFIG_FILE" ] || fail "Configuration file is not readable: $CONFIG_FILE"

source "$CONFIG_FILE" || fail "Unable to load configuration file: $CONFIG_FILE"

require_var "GSETTINGS_SCHEMA_DIR"
require_var "XDG_DATA_DIRS"
require_var "DARKTABLE_BIN"
require_var "DARKTABLE_CONFIG_DIR"
require_var "DARKTABLE_CACHE_DIR"

[ -d "$GSETTINGS_SCHEMA_DIR" ] || fail "GSETTINGS_SCHEMA_DIR not found: $GSETTINGS_SCHEMA_DIR"
[ -d "$XDG_DATA_DIRS" ] || fail "XDG_DATA_DIRS not found: $XDG_DATA_DIRS"
[ -x "$DARKTABLE_BIN" ] || fail "DARKTABLE_BIN not found or not executable: $DARKTABLE_BIN"
[ -d "$DARKTABLE_CONFIG_DIR" ] || fail "DARKTABLE_CONFIG_DIR not found: $DARKTABLE_CONFIG_DIR"
[ -d "$DARKTABLE_CACHE_DIR" ] || fail "DARKTABLE_CACHE_DIR not found: $DARKTABLE_CACHE_DIR"

log "Configuration file: $CONFIG_FILE"
log "GSETTINGS_SCHEMA_DIR=$GSETTINGS_SCHEMA_DIR"
log "XDG_DATA_DIRS=$XDG_DATA_DIRS"
log "DARKTABLE_BIN=$DARKTABLE_BIN"
log "DARKTABLE_CONFIG_DIR=$DARKTABLE_CONFIG_DIR"
log "DARKTABLE_CACHE_DIR=$DARKTABLE_CACHE_DIR"

notify "Launching DracoTable"

GSETTINGS_SCHEMA_DIR="$GSETTINGS_SCHEMA_DIR" \
XDG_DATA_DIRS="$XDG_DATA_DIRS" \
"$DARKTABLE_BIN" \
  --configdir "$DARKTABLE_CONFIG_DIR" \
  --cachedir "$DARKTABLE_CACHE_DIR" \
|| fail "Failed to launch DracoTable"

log "DracoTable closed successfully"
exit 0
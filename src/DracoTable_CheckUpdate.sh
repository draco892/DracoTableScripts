#!/bin/bash

set -u
set -o pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${BASE_DIR}/conf"
CONFIG_FILE="${CONFIG_DIR}/DracoTable_CheckUpdate.conf"

log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

fail() {
    local msg="$1"
    echo "ERROR: $msg" >&2
    osascript -e 'display dialog "Darktable build failed:\n'"$msg"'" buttons {"OK"} default button "OK" with icon stop'
    exit 1
}

notify() {
    local msg="$1"
    osascript -e 'display notification "'"$msg"'" with title "Darktable build"'
}

run_step() {
    local msg="$1"
    shift
    log "$msg"
    "$@" || fail "$msg"
}

require_var() {
    local var_name="$1"
    local var_value="${!var_name:-}"

    if [ -z "$var_value" ]; then
        fail "Missing or empty required configuration field: $var_name"
    fi
}

log "Starting darktable update/build script"
notify "Starting darktable update"

[ -d "$SCRIPT_DIR" ] || fail "Script directory not found: $SCRIPT_DIR"
[ -d "$BASE_DIR" ] || fail "Base directory not found: $BASE_DIR"
[ -d "$CONFIG_DIR" ] || fail "Configuration directory not found: $CONFIG_DIR"
[ -e "$CONFIG_FILE" ] || fail "Configuration file not found: $CONFIG_FILE"
[ -f "$CONFIG_FILE" ] || fail "Configuration path is not a regular file: $CONFIG_FILE"
[ -r "$CONFIG_FILE" ] || fail "Configuration file is not readable: $CONFIG_FILE"

source "$CONFIG_FILE" || fail "Unable to load configuration file: $CONFIG_FILE"

require_var "PROJECT_DIR"
require_var "PREFIX_DIR"
require_var "INSTALL_PREFIX"
require_var "LUA_PREFIX"
require_var "HOMEBREW_BIN"

export PATH="${HOMEBREW_BIN}:$PATH"

[ -d "$PROJECT_DIR" ] || fail "Project directory not found: $PROJECT_DIR"
[ -d "$LUA_PREFIX" ] || fail "Lua prefix directory not found: $LUA_PREFIX"
[ -d "$HOMEBREW_BIN" ] || fail "Homebrew bin directory not found: $HOMEBREW_BIN"

cd "$PROJECT_DIR" || fail "Unable to enter directory: $PROJECT_DIR"

export CMAKE_PREFIX_PATH="${LUA_PREFIX}:${CMAKE_PREFIX_PATH:-}"
export PREFIX="$PREFIX_DIR"

log "Script directory: $SCRIPT_DIR"
log "Base directory: $BASE_DIR"
log "Configuration file: $CONFIG_FILE"
log "Current directory: $(pwd)"
log "CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH"
log "PREFIX=$PREFIX"

command -v git >/dev/null 2>&1 || fail "git not found"

if ! command -v cmake >/dev/null 2>&1; then
    command -v brew >/dev/null 2>&1 || fail "Homebrew not found and cmake is missing"
    run_step "Installing cmake with Homebrew" brew install cmake
fi

[ -x "./build.sh" ] || fail "build.sh not found or not executable"

run_step "Running git fetch --all --prune" git fetch --all --prune

UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)" || fail "No upstream branch configured for the current branch"
LOCAL_COMMIT="$(git rev-parse HEAD)" || fail "Unable to read local commit"
REMOTE_COMMIT="$(git rev-parse @{u})" || fail "Unable to read remote commit"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)" || fail "Unable to read current branch"

log "Current branch: $CURRENT_BRANCH"
log "Tracked upstream branch: $UPSTREAM"

if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    log "No updates available: local and remote are already in sync"
    notify "No darktable updates to build"
    osascript -e 'display dialog "No updates available for darktable.\nYour local branch is already up to date with the remote repository." buttons {"OK"} default button "OK" with icon note'
    exit 0
fi

BEHIND_AHEAD="$(git rev-list --left-right --count HEAD...@{u} 2>/dev/null)" || fail "Unable to compare local and remote branches"
AHEAD_COUNT="$(echo "$BEHIND_AHEAD" | awk '{print $1}')"
BEHIND_COUNT="$(echo "$BEHIND_AHEAD" | awk '{print $2}')"

log "Local-only commits: $AHEAD_COUNT"
log "Remote-only commits: $BEHIND_COUNT"

if [ "$BEHIND_COUNT" = "0" ] && [ "$AHEAD_COUNT" -gt 0 ]; then
    log "Local branch is ahead of remote. Pull/build will be skipped for safety"
    notify "Local branch ahead of remote"
    osascript -e 'display dialog "Your local branch contains commits that are not present on the remote.\nFor safety, the automatic pull and build have been skipped." buttons {"OK"} default button "OK" with icon caution'
    exit 0
fi

run_step "Running git pull" git pull
run_step "Removing build directory" rm -rf build
run_step "Starting build and installation" ./build.sh --install --build-type RelWithDebInfo --prefix "$INSTALL_PREFIX"

log "Build completed successfully"
notify "Darktable build completed"
osascript -e 'display dialog "Darktable build completed successfully." buttons {"OK"} default button "OK" with icon note'

exit 0
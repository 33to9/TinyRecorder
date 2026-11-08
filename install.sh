#!/bin/bash
# TinyRecorder installer
#
#   curl -fsSL https://raw.githubusercontent.com/33to9/TinyRecorder/main/install.sh | bash
#
# Downloads the latest release from GitHub, checks its SHA-256 and code signature,
# and installs it to /Applications. Files downloaded with curl carry no quarantine
# flag, so macOS doesn't block the first launch.
#
# Options (environment variables):
#   TINYRECORDER_VERSION=1.7.19   install a specific version instead of the latest
#   TINYRECORDER_NO_OPEN=1        don't launch the app after installing
set -euo pipefail

REPO="33to9/TinyRecorder"
APP_NAME="TinyRecorder.app"
BUNDLE_ID="com.33to9.TinyRecorder"
DEST_DIR="/Applications"

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# Everything runs inside main, so a partially downloaded script never executes.
main() {
    [ "$(uname -s)" = "Darwin" ] || fail "TinyRecorder only runs on macOS."
    local os_major
    os_major=$(sw_vers -productVersion | cut -d. -f1)
    [ "$os_major" -ge 12 ] || fail "TinyRecorder requires macOS 12.3 or later."

    local api="https://api.github.com/repos/${REPO}/releases/latest"
    [ -n "${TINYRECORDER_VERSION:-}" ] && api="https://api.github.com/repos/${REPO}/releases/tags/v${TINYRECORDER_VERSION#v}"

    say "Looking up the release…"
    local json
    json=$(curl -fsSL -H "Accept: application/vnd.github+json" "$api") \
        || fail "Could not reach GitHub (${api})."

    local tag url digest
    tag=$(printf '%s' "$json" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
    url=$(printf '%s' "$json" | grep -o '"browser_download_url": *"[^"]*_macOS\.zip"' | head -1 | sed 's/.*"\(https[^"]*\)"$/\1/')
    [ -n "$tag" ] && [ -n "$url" ] || fail "No macOS zip found in release ${tag:-?}."
    # GitHub publishes a sha256 digest per asset; it appears just before its download URL.
    digest=$(printf '%s' "$json" | tr ',' '\n' | grep -E '"digest"|"browser_download_url"' \
        | grep -B1 '_macOS\.zip"' | grep -o 'sha256:[0-9a-f]\{64\}' | head -1 | cut -d: -f2 || true)

    local tmp
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    say "Downloading TinyRecorder ${tag}…"
    curl -fL --progress-bar -o "$tmp/TinyRecorder.zip" "$url" || fail "Download failed."

    if [ -n "$digest" ]; then
        local actual
        actual=$(shasum -a 256 "$tmp/TinyRecorder.zip" | cut -d' ' -f1)
        [ "$actual" = "$digest" ] || fail "Checksum mismatch (expected ${digest}, got ${actual})."
        say "Checksum OK."
    fi

    ditto -x -k "$tmp/TinyRecorder.zip" "$tmp/unzipped" || fail "Could not unpack the download."
    local app="$tmp/unzipped/${APP_NAME}"
    [ -d "$app" ] || fail "${APP_NAME} not found in the download."
    # The checksum above is the integrity check; the signature check is informational
    # (the app is self-signed, not notarized).
    codesign --verify --deep "$app" 2>/dev/null || say "Warning: code signature could not be verified."
    [ "$(defaults read "$app/Contents/Info.plist" CFBundleIdentifier)" = "$BUNDLE_ID" ] \
        || fail "Unexpected bundle identifier."

    # Quit a running copy so it can be replaced.
    if pgrep -xq TinyRecorder; then
        say "Quitting the running TinyRecorder…"
        osascript -e "tell application id \"${BUNDLE_ID}\" to quit" >/dev/null 2>&1 || true
        local i
        for i in $(seq 1 20); do pgrep -xq TinyRecorder || break; sleep 0.5; done
        pgrep -xq TinyRecorder && fail "TinyRecorder is still running (recording?). Quit it and try again."
    fi

    # /Applications is writable for admin users; otherwise ask for sudo.
    local sudo=""
    [ -w "$DEST_DIR" ] || sudo="sudo"
    [ -e "$DEST_DIR/$APP_NAME" ] && [ ! -w "$DEST_DIR/$APP_NAME" ] && sudo="sudo"
    [ -n "$sudo" ] && say "Administrator password needed to write to ${DEST_DIR}."

    say "Installing to ${DEST_DIR}…"
    $sudo rm -rf "$DEST_DIR/$APP_NAME"
    $sudo ditto "$app" "$DEST_DIR/$APP_NAME"
    # curl downloads aren't quarantined, but clear it anyway in case the zip was.
    $sudo xattr -dr com.apple.quarantine "$DEST_DIR/$APP_NAME" 2>/dev/null || true

    link_cli

    say "TinyRecorder ${tag} installed. Future updates: TinyRecorder → Check for Updates…"
    if [ -z "${TINYRECORDER_NO_OPEN:-}" ]; then
        open "$DEST_DIR/$APP_NAME"
    fi
}

# Links the `tinyrecorder` command into /usr/local/bin when that needs no password,
# otherwise says how to do it. Never replaces a file that isn't our link.
link_cli() {
    local cli="$DEST_DIR/$APP_NAME/Contents/Resources/tinyrecorder"
    local link="/usr/local/bin/tinyrecorder"
    [ -x "$cli" ] || return 0
    if [ -L "$link" ] || { [ ! -e "$link" ] && [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; }; then
        if [ ! -L "$link" ] || [ -w /usr/local/bin ]; then
            ln -sf "$cli" "$link" && { say "Command-line tool: tinyrecorder (run 'tinyrecorder help')."; return 0; }
        fi
    fi
    say "Command-line tool (optional): sudo ln -sf \"$cli\" $link"
}

main "$@"

#!/bin/bash
# Takes the website screenshots of the installed TinyRecorder in each language.
# Runs on a GitHub-hosted macOS runner (see .github/workflows/screenshots.yml).
#   capture.sh <out-dir> <lang>...
# For each language it writes <out>/<lang>/{toolbar,picker,settings}.png plus debug-*.png
# full-screen images and window lists, so a failed step can be diagnosed from the artifact.
set -uo pipefail
OUT="$1"; shift
APP=/Applications/TinyRecorder.app
WINDOWS=/tmp/windows   # compiled from windows.swift

log()  { printf '\n==> %s\n' "$*"; }
app_pid() { pgrep -n -f "$APP/Contents/MacOS/"; }
# Debug: full screen + every window on screen (all apps), to diagnose a failed step.
snap() { screencapture -x "$OUT/$lang/debug-$1.png"; "$WINDOWS" > "$OUT/$lang/debug-$1.txt" 2>&1; }
# First TinyRecorder window whose size matches the awk condition; prints "id x y w h".
find_win() { "$WINDOWS" "$(app_pid)" 2>/dev/null | awk -F'\t' "$1 { print \$1, \$2, \$3, \$4, \$5; exit }"; }
grab() {   # grab <name> <awk-condition>
  read -r id x y w h <<<"$(find_win "$2")"
  if [ -n "${id:-}" ]; then screencapture -x -o -l "$id" "$OUT/$lang/$1.png" && echo "saved $1 (${w}x${h})"
  else echo "MISSING $1"; fi
}

for lang in "$@"; do
  mkdir -p "$OUT/$lang"
  log "$lang: system language + other apps"
  # Other apps' window titles show up in the picker, so they must be in the same language.
  defaults write -g AppleLanguages -array "$lang"
  pkill -f "$APP/Contents/MacOS/"; killall TextEdit Calculator Finder 2>/dev/null; sleep 3
  open -a Calculator; open -a TextEdit; open /Applications; sleep 5

  log "$lang: launch"
  open -n "$APP" --args -AppleLanguages "($lang)"
  sleep 10; snap 1-launch

  log "$lang: toolbar"
  open "$APP"; sleep 4; snap 2-toolbar   # a second open = reopen, which shows the recording toolbar
  grab toolbar '$4 >= 700 && $5 <= 160'
  read -r _ tx ty tw th <<<"$(find_win '$4 >= 700 && $5 <= 160')"

  log "$lang: preferences"
  osascript -e 'tell application "TinyRecorder" to activate' -e 'delay 1' \
            -e 'tell application "System Events" to keystroke "," using command down'
  sleep 5; snap 3-settings
  # Third sidebar page (Output: format, encoder, audio); rows are ~31 pt apart.
  read -r _ sx sy sw sh <<<"$(find_win '$5 > 300')"
  if [ -n "${sx:-}" ]; then cliclick "c:$((sx + 60)),$((sy + 166))"; sleep 3; snap 4-settings-output; fi
  grab settings '$5 > 300'
  osascript -e 'tell application "System Events" to keystroke "w" using command down'; sleep 2

  if [ -n "${tw:-}" ]; then
    log "$lang: window picker"
    # Toolbar buttons are laid out evenly; "Window" is the 5th of 7.
    cliclick "c:$((tx + tw * 9 / 14)),$((ty + th / 2))"; sleep 6
    read -r _ px py pw ph <<<"$(find_win '$5 > 300')"
    if [ -n "${px:-}" ]; then
      cliclick "c:$((px + 107)),$((py + 115))"; sleep 2      # select the first window thumbnail
      snap 5-picker; grab picker '$5 > 300'

      log "$lang: recording → menu bar"
      cliclick "c:$((px + pw - 62)),$((py + ph - 53))"        # Start
      sleep 8; snap 6-recording
      # Only TinyRecorder's own menu bar items (status icon, timer, camera), not the system clock.
      screencapture -x -R "592,0,212,24" "$OUT/$lang/menubar.png" && echo "saved menubar (region)"
    else echo "MISSING picker"; fi
  fi
  pkill -f "$APP/Contents/MacOS/"; sleep 2
done

#!/usr/bin/env bash
# Installs Farscreen Microphone (the Audio Server plug-in from macos/AudioDriver) on this Mac, the
# same as This Mac → Microphone → Install in the app: Macs that view this one can then share their
# microphones with its apps. Asks for your password (sudo), and restarts this Mac's audio for a
# moment, which interrupts whatever is playing or recording.
#
#   ./scripts/install-audio-driver.sh            install or update (builds it first)
#   ./scripts/install-audio-driver.sh --remove   remove it
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="/Library/Audio/Plug-Ins/HAL/LanKVMMicrophone.driver"

if [[ "${1:-}" == "--remove" ]]; then
    sudo rm -rf "$TARGET"
    sudo killall coreaudiod
    echo "Removed Farscreen Microphone."
    exit 0
fi

./scripts/build-audio-driver.sh
sudo rm -rf "$TARGET"
sudo ditto target/release/LanKVMMicrophone.driver "$TARGET"
sudo chown -R root:wheel "$TARGET"
# launchd starts it again at once, and it loads the plug-ins it finds.
sudo killall coreaudiod
for _ in {1..20}; do
    system_profiler SPAudioDataType 2>/dev/null | grep -q "Farscreen Microphone:" && break
    sleep 0.5
done
if system_profiler SPAudioDataType 2>/dev/null | grep -q "Farscreen Microphone:"; then
    echo "Installed: apps can now choose Farscreen Microphone."
else
    echo "Installed, but this Mac's audio hasn't loaded it yet; restart the Mac if it doesn't show up." >&2
fi

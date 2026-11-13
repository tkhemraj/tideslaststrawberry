#!/usr/bin/env bash
# 🍓 tides last straw(berry) — tear-down. Leaves the mprisence binary alone
# (run `cargo uninstall mprisence` yourself if you want it gone too).
set -euo pipefail
pink(){ printf '\033[38;5;206m🍓 %s\033[0m\n' "$*"; }

systemctl --user disable --now mprisence 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/mprisence.service"
systemctl --user daemon-reload
pink "service stopped, disabled, and removed."
pink "config left at ~/.config/mprisence/config.toml — delete it by hand if you like."
pink "engine still installed — remove with: cargo uninstall mprisence"

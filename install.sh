#!/usr/bin/env bash
# 🍓 tides last straw(berry) — Strawberry → Discord Rich Presence, in one command.
# Userspace only: no sudo, no system files touched.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pink(){ printf '\033[38;5;206m🍓 %s\033[0m\n' "$*"; }
warn(){ printf '\033[33m•  %s\033[0m\n' "$*"; }
die(){  printf '\033[31m✗  %s\033[0m\n' "$*" >&2; exit 1; }

# 1. Dependencies -------------------------------------------------------------
command -v cargo >/dev/null || die "Rust/cargo not found. Install rustup first: https://rustup.rs"
command -v systemctl >/dev/null || die "systemd (systemctl --user) is required."
pgrep -x Discord >/dev/null 2>&1 || command -v discord >/dev/null 2>&1 \
  || warn "Discord desktop doesn't appear to be installed/running — Rich Presence needs it."

# 2. Engine: mprisence --------------------------------------------------------
BIN="$HOME/.cargo/bin/mprisence"
if command -v mprisence >/dev/null 2>&1; then BIN="$(command -v mprisence)"; fi
if [ ! -x "$BIN" ]; then
  pink "installing mprisence (the MPRIS→Discord engine)…"
  cargo install mprisence
  BIN="$HOME/.cargo/bin/mprisence"
else
  pink "mprisence already installed — $("$BIN" --version 2>/dev/null || echo present)"
fi
[ -x "$BIN" ] || die "mprisence install did not produce a binary at $BIN"

# 3. Config (don't clobber an existing one) -----------------------------------
CFG="$HOME/.config/mprisence/config.toml"
if [ -f "$CFG" ]; then
  pink "keeping your existing config ($CFG); ours is in ./config.toml if you want it"
else
  pink "writing tuned config → $CFG"
  mkdir -p "$(dirname "$CFG")"
  install -m644 "$HERE/config.toml" "$CFG"
fi

# 4. User service -------------------------------------------------------------
UNIT="$HOME/.config/systemd/user/mprisence.service"
pink "installing user service → $UNIT"
mkdir -p "$(dirname "$UNIT")"
install -m644 "$HERE/mprisence.service" "$UNIT"
systemctl --user daemon-reload
systemctl --user enable --now mprisence

# 5. Verify -------------------------------------------------------------------
sleep 2
if systemctl --user is-active --quiet mprisence; then
  pink "live. play something in Strawberry and check your Discord profile."
  pink "logs: journalctl --user -u mprisence -f"
else
  die "service failed to start — see: journalctl --user -u mprisence -n 30"
fi

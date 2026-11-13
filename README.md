<div align="center">

# 🍓 tides last straw(berry)

### Put what **Strawberry** is playing on your **Discord** — track, artist, album, cover art, the works.

[![license](https://img.shields.io/badge/license-MIT-ff4d6d)](LICENSE)
[![shell](https://img.shields.io/badge/install-one%20command-ff4d6d)](install.sh)
[![platform](https://img.shields.io/badge/platform-Linux-ff4d6d)](#requirements)
[![engine](https://img.shields.io/badge/engine-mprisence-ff4d6d)](https://github.com/lazykern/mprisence)

</div>

---

> **Origin story.** This started as a typo. The ask was *"make my tidal show what strawberry is playing."*
> Tidal doesn't do that. Strawberry → Discord does. So Tidal got the boot and this got a name.
> **The last straw. Strawberry.** 🍓

---

## What it does

[Strawberry](https://www.strawberrymusicplayer.org/) speaks **MPRIS** over D-Bus. Discord shows
**Rich Presence** over a local IPC socket. This wires one to the other and runs it as a
background user service, so your Discord profile quietly shows:

```
┌──────────────────────────────────────┐
│  Listening to Strawberry      🍓      │
│  ┌────┐                               │
│  │cover│  Talisman (Vegyn Version)    │   ← song  (details)
│  │ art │  Wednesday                   │   ← artist (state)
│  └────┘  Talisman (2024)              │   ← album  (large text)
│          ▓▓▓▓▓▓░░░░░░  2:14           │   ← elapsed time
└──────────────────────────────────────┘
```

Album art is fetched automatically (MusicBrainz / Catbox). Works for local files **and**
streamed sources (Tidal, Subsonic, radio) since Strawberry streaming is allowed.

## Requirements

- **Linux** with a systemd user session (`systemctl --user`)
- **[Rust / cargo](https://rustup.rs)** — the engine builds from source
- **Discord desktop app** running (Rich Presence rides its local IPC socket — the web app can't)
- **Strawberry** — and in Discord: *Settings → Activity Privacy → "Share your detected activities with others"* **on**

## Install

```bash
git clone https://github.com/tkhemraj/tideslaststrawberry
cd tideslaststrawberry
./install.sh
```

Then play something in Strawberry and look at your Discord profile. That's it.

The installer is idempotent: it installs [`mprisence`](https://github.com/lazykern/mprisence)
(the MPRIS→Discord engine) into `~/.cargo/bin`, drops the tuned [`config.toml`](config.toml)
(only if you don't already have one), installs the user service, and enables it — **all in
userspace, no `sudo`.**

## "It says it's installed but nothing shows up" 🍓

The #1 gotcha, and the reason this repo exists. Installing the binary does **not** start it.
You need the service **enabled and running**:

```bash
systemctl --user enable --now mprisence
systemctl --user is-active mprisence          # -> active
journalctl --user -u mprisence -n 20          # -> "Updated Discord activity for Strawberry - ..."
```

If it's `active` but Discord is still blank, it's almost always one of three things:

1. **Activity type.** Discord silently drops third-party **"Listening"** presences for
   non-whitelisted apps — it only reliably renders **"Playing"**. The shipped config forces
   it (`[activity_type] default = "playing"`, and `override_activity_type = "playing"` on
   Strawberry). If you see `Updated Discord activity … (Playing)` in the logs but nothing on
   your profile, this was the culprit — make sure you're on a config with the Playing override.
2. **Activity Privacy.** Discord → Settings → **Activity Privacy → "Share your detected
   activities with others"** must be **on**.
3. The **desktop** Discord app is running (not just the browser tab).

Confirm the daemon's side with `journalctl --user -u mprisence -n 5` — a line like
`Updated Discord activity for Strawberry - <track> (Playing)` means mprisence did its job and
any remaining blank is one of the Discord-side toggles above.

## Make it yours

Everything lives in `~/.config/mprisence/config.toml`. The shipped config turns on elapsed
time, album art, and streaming. A few knobs:

```toml
[activity_type]
use_content_type = false   # don't auto-pick "listening" (Discord drops it)
default = "playing"        # "playing" renders reliably

[time]
show = true
as_elapsed = true          # elapsed, not remaining

[cover.provider]
provider = ["musicbrainz", "catbox"]

[template]
details = "{{{title}}}"                # top line
state   = "{{{artist_display}}}"       # second line
large_text = "{{{album}}}"             # hover-over-cover text

[player.strawberry]
allow_streaming = true         # show Tidal/Subsonic/radio tracks too
show_icon = true
override_activity_type = "playing"
```

Verify any change with `mprisence config show`, then `systemctl --user restart mprisence`.
Full option list: the [mprisence docs](https://github.com/lazykern/mprisence).

## Uninstall

```bash
./uninstall.sh            # stops + disables the service, removes the unit
# and, if you want the engine gone too:
cargo uninstall mprisence
```

## Credits

The heavy lifting is [**mprisence**](https://github.com/lazykern/mprisence) by
[@lazykern](https://github.com/lazykern) — a genuinely great MPRIS→Discord Rich Presence
daemon. This repo is just the Strawberry-flavored, one-command, "why-isn't-it-showing"-proof
wrapper around it.

## License

MIT — see [LICENSE](LICENSE).

# How it works

## Profile isolation

Grok Bot is an Electron app with a single-instance lock tied to its data folder. `gbp` starts an extra instance with:

```bash
open -n -a "Grok Bot" \
  --env SAND_USER_DATA_DIR=<profile> \
  --env SAND_DATA_ROOT=<profile>/sand-data \
  --env CUA_APP_SUPPORT_DIR=<profile>/cua
```

* `SAND_USER_DATA_DIR` moves that instance's user data (cookies, settings, the single-instance lock) into the profile folder, so it can run next to your default instance and stay signed in to a different account.
* `SAND_DATA_ROOT` keeps its local state, logs and local-tools daemon inside the profile folder. Grok Bot would default to `<profile>/sand-data` anyway, but setting it explicitly means it can never fall back to the shared folder your default instance uses.
* `CUA_APP_SUPPORT_DIR` gives the computer-use helper its own support folder inside the profile.

These are undocumented environment variables that a Grok Bot update could change.

`gbp` tells instances apart by the `--user-data-dir` flag that each instance's child processes carry, so `list`, `quit` and launching always target exactly one instance by PID.

The Grok Bot app bundle is never modified, copied or re-signed, so app updates keep working.

## The badge helper

`grok-badge` is a small Swift program (`launcher/src/GrokBadge.swift`, built by `launcher/scripts/build.sh`). It's a click-through floating panel that:

* finds the instance's window using only `CGWindowListCopyWindowInfo` (window owner PID and bounds: no window titles, no screen capture, no Accessibility), so it needs no macOS permissions;
* shows only while that instance is frontmost, unless `--always` is set;
* hides when the window is minimized or on another Space, and exits when the instance quits.

It also renders the icons used for shortcuts (`--render-icon`) and brings an instance to the front (`--activate`).

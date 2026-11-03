# Contributing

Thanks for helping. Ground rules:

* Keep `launcher/bin/gbp` compatible with the stock macOS bash 3.2 and `shellcheck`-clean (`shellcheck launcher/bin/gbp launcher/scripts/build.sh`).
* `grok-badge` must stay permission-free: CGWindowList owner PID / bounds only. No window titles, Accessibility, screen capture or Apple Events.
* Never kill, signal or AppleScript-quit Grok Bot by name in code or docs; target one PID found through its `--user-data-dir`.
* Never modify, copy or re-sign the Grok Bot app bundle.
* Don't commit personal data: IPs, hostnames, usernames, emails, tailnet names, profile folders, logs. Put local notes in `LOCAL_NOTES.md` (gitignored).
* Add a line to `CHANGELOG.md` for user-visible changes. Every command needs `--help` text.

Build the helper with `launcher/scripts/build.sh`. The binary is gitignored.

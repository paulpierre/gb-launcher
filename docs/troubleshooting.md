# Troubleshooting

## First sign-in of a new profile

macOS delivers the browser's `grokbot://` sign-in link to **one** running Grok Bot, normally your default one, not the new profile that started the login. Signing in a new profile while the default is running can disrupt the default instance. Do the one-time sign-in in this order:

1. Quit your default Grok Bot normally, from its menu or Dock icon.
2. Run `gbp <profile>` and sign in.
3. Reopen the default with `open -a "Grok Bot"`.

After that first sign-in, both run side by side. `gbp` prints this reminder when it sees a profile that has never been signed in.

## Known limitations

* **The Dock and Cmd+Tab can't be badged.** Every instance shows the same Grok Bot icon there. Use the window badge, or shortcuts with per-profile icons.
* **`grokbot://` links go to one instance**, usually the default one. This covers sign-in callbacks and links clicked in other apps.
* **Extra profiles can disrupt the default instance's computer (local tools) connection.** Grok Bot is built for one registered computer per Mac. Keep the default profile as your computer and use extra profiles for chat.
* **Recovery:** if the default's computer shows offline, restart **only the default** Grok Bot. Extra profiles can keep running.
* **macOS permissions are shared, and changing them quits every instance.** Permissions belong to the Grok Bot app, so every profile shares them. Changing one in System Settings ("Quit & Reopen"), or installing a Grok Bot update, quits every instance and reopens only the default. Run `gbp <profile>` again afterwards.
* **Never** use `pkill "Grok Bot"` or AppleScript `quit`, because they hit every instance. Use `gbp quit <profile>`.

## Fixes

* **No badge:** bring the profile to the front, because the badge shows only while it's frontmost. Then run `gbp badge <profile> --debug` and check `~/GrokBotProfiles/<profile>/badge.log` for `shown` / `hidden (...)` lines with the window frame and frontmost PID. `--always` keeps it visible behind other apps.
* **`grok-badge` missing:** run `~/gb-launcher/launcher/scripts/build.sh`. It needs the Xcode Command Line Tools (`xcode-select --install`).
* **"no instance for '<profile>' appeared":** Grok Bot may have changed how profiles work, or it's still starting. Check `~/GrokBotProfiles/<profile>/launch.log`, or raise `GBP_LAUNCH_TIMEOUT`.
* **`gbp: command not found`:** `~/.local/bin` isn't on your PATH. Open a new Terminal window, or run the install block from the README again.

## Uninstall

```bash
gbp uninstall
```

It lists what it will remove and asks `Continue? [y/N]`. Then it:

* quits every running extra profile and its badge (never your default Grok Bot);
* removes GB Launcher shortcuts in `~/Desktop`, `~/Applications` and `/Applications`, matched only by their bundle id (`io.gblauncher.profile.*`, or the older `io.gbghost.profile.*`), so no other app is touched;
* removes `~/.local/bin/gbp`, only if it's a symlink into this GB Launcher folder;
* removes the exact line `export PATH="$HOME/.local/bin:$PATH"` from `~/.zshrc`, after backing it up to `~/.zshrc.gbp-backup`. Other tools you keep in `~/.local/bin` may rely on that line; use `--keep-path` to leave it;
* deletes the GB Launcher folder (the clone) last.

It asks separately, `Also delete your profiles and their sign-ins in ~/GrokBotProfiles? [y/N]`. The default is no, so profiles are kept unless you say yes.

| Flag | Effect |
|---|---|
| `--yes` | Don't ask. Profiles are still **kept** unless you also pass `--delete-profiles` |
| `--delete-profiles` | Also delete every profile folder and its sign-ins |
| `--keep-path` | Leave `~/.zshrc` unchanged |
| `--keep-repo` | Leave the GB Launcher folder in place |

It never touches the Grok Bot app or your default Grok Bot data.

### Manual uninstall

If `gbp` no longer works, quit each running profile first (`gbp list` shows them), then:

```bash
gbp quit work
gbp shortcut --remove work
rm ~/.local/bin/gbp
rm -rf ~/GrokBotProfiles/work
rm -rf ~/gb-launcher
```

* Repeat `gbp shortcut --remove` with `--applications` or `--dest` if you made shortcuts there.
* `rm -rf ~/GrokBotProfiles/work` deletes that profile's sign-in and data.
* Remove the `export PATH=...` line from `~/.zshrc` if you added it only for gbp.

Your default Grok Bot and its data are not touched by any of this.

## Safety

Profile folders contain live session cookies and encrypted secrets. Don't sync, share or commit them. See [SECURITY.md](../SECURITY.md) and [CONTRIBUTING.md](../CONTRIBUTING.md).

# Changelog

## Unreleased

### Added
* `gbp` profile launcher: picker, launch/activate, `list`, `new`, `edit`, `quit`, `badge`, `shortcut` (`--all`, `--remove`, `--dest`, `--applications`), per-command `--help`.
* `grok-badge` helper: click-through colored, numbered badge (optional icon and border) pinned to the profile's window. Shown only while that instance is frontmost (`--always` to override), `--debug` placement logging, offscreen icon rendering for shortcuts.
* Extra profiles get an explicit `SAND_DATA_ROOT` inside the profile folder.
* Renamed project to GB Launcher; shortcut bundle ids are now `io.gblauncher.profile.<name>` (`gbp shortcut --remove` also removes old `io.gbghost.*` ones).
* First-sign-in warning: macOS routes `grokbot://` callbacks to the default instance.
* `gbp new` uses smart defaults: no prompts, next number, next unused color, "Profile N" name, unique folder. `gbp new -i` asks for each setting with those defaults pre-filled; the picker's `n` offers to launch the new profile.
* Shorter README with a copy-paste install; detailed docs moved to `docs/`.

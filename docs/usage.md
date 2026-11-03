# Usage

## Commands

| Command | What it does |
|---|---|
| `gbp` | Interactive picker: choose a profile, `n` for a new one (then offers to launch it), `q` to cancel |
| `gbp <profile>` | Launch a profile, or bring it to the front if it's already running |
| `gbp list` | Every profile with its number, color, icon and running PID or "stopped" |
| `gbp new [name]` | Create a profile right away with smart defaults (see below) |
| `gbp new -i [name]` | Create a profile, asking for each setting (Enter accepts each default) |
| `gbp edit <profile>` | Change name, number, color, icon, border, badge visibility |
| `gbp quit <profile> [--force]` | Quit only that profile's instance (`default` needs `--force`) |
| `gbp badge <profile> [--debug] [--always]` | Restart the badge for a running profile |
| `gbp shortcut ...` | Create or remove double-clickable launchers (see below) |
| `gbp uninstall` | Remove gbp, its shortcuts and PATH line; asks before deleting profiles ([details](troubleshooting.md#uninstall)) |
| `gbp help <command>` or `gbp <command> --help` | Help for any command |

`<profile>` can be the folder name, the display name, or the number. `default` (or `1`) is your normal Grok Bot. It never gets a badge, and `gbp quit default` needs `--force`.

## Creating profiles

`gbp new` asks nothing and picks:

* **Name:** "Profile N", or the name you pass (`gbp new Work`).
* **Number:** the next free number. Default is 1, so your first new profile is 2.
* **Color:** the next preset color no profile uses yet, in this order: purple, blue, green, orange, red, pink, teal, yellow, indigo, cyan. Gray is reserved for Default. Once all are used, colors repeat by number.
* **Folder:** made from the name (`work`). If it's taken, `work-2`, `work-3`, and so on.
* No icon and no border.

It then prints how to launch the profile and how to change it.

`gbp new -i` asks for the name, number, color (a preset name, its number in the list, or `#RRGGBB`), an optional icon image (png, jpg or icns, copied into the profile as `icon.png`) and whether to draw a colored border. Every prompt is pre-filled with the smart default, so pressing Enter accepts it.

`gbp edit <profile>` asks the same questions, pre-filled with the current values. Press Enter to keep a value, or type `none` to clear the icon. If the profile is running, its badge restarts with the new settings.

## Where profiles live

Profiles live in `~/GrokBotProfiles/<folder>/`. Set `GBP_HOME` to use another folder. Each has a `profile.json`:

```json
{ "name": "Work", "number": 2, "color": "#8B5CF6", "icon": "", "border": false }
```

Add `"always": true` to keep the badge visible while other apps are in front.

Other environment variables:

| Variable | Default | Purpose |
|---|---|---|
| `GBP_HOME` | `~/GrokBotProfiles` | Where profiles live |
| `GBP_APP` | `/Applications/Grok Bot.app` | The Grok Bot app to launch |
| `GBP_LAUNCH_TIMEOUT` | `30` | Seconds to wait for a new instance to appear |
| `GBP_BADGE_DEBUG=1` | off | Log badge placement for every launch |
| `GBP_BADGE_ALWAYS=1` | off | Show badges even while other apps are in front |

## Badges

Every extra profile gets a click-through badge with its color and number (and icon, if set), pinned to its window. By default it shows only while that instance is the frontmost app and its window is on screen. It hides when the window is minimized or on another Space, and exits when the instance quits.

* `gbp badge <profile>` restarts it, for example after editing colors by hand.
* `--always` keeps it visible while other apps are in front.
* `--debug` logs placement details to `~/GrokBotProfiles/<profile>/badge.log`.

## Shortcuts

`gbp shortcut` creates `Grok Bot - <name>.app`, a tiny double-clickable launcher that runs `gbp <profile>`. Its icon is the profile's icon, or a colored tile with the profile number.

```bash
gbp shortcut work
gbp shortcut work --applications
gbp shortcut work --dest /Applications
gbp shortcut --all
gbp shortcut --remove work
```

* With no option, the shortcut goes on your Desktop (`~/Desktop`).
* `--applications` uses `~/Applications`. Drag it to the Dock from there.
* `--dest <folder>` uses any folder. `/Applications` needs an admin account.
* `--all` makes one for Default plus every profile.
* `--remove` deletes that profile's shortcut. Add the same `--applications` or `--dest` you created it with.

The first time you write to the Desktop, macOS may ask once whether Terminal (or your terminal app) may access the Desktop folder. Allow it, or use `--applications`.

# Security

## Reporting

Please report security issues privately to the repository owner (GitHub private vulnerability reporting or a direct message) rather than in a public issue.

## Model

* `gbp` runs as you and only starts Grok Bot with environment variables. It never modifies, copies or re-signs the Grok Bot bundle, and never reads Grok Bot secrets.
* `grok-badge` reads only window owner PID, number, layer, alpha and bounds from `CGWindowListCopyWindowInfo`. It requests no TCC permission (Screen Recording, Accessibility, Automation, Files & Folders).
* Profile folders (`~/GrokBotProfiles/*`) hold live session cookies and encrypted secrets with the same sensitivity as Grok Bot's own data folder. Keep them out of backups you share, sync folders and git.
* Shortcut `.app` bundles are unsigned local scripts that `exec` your `gbp`. Only create them from a checkout you trust.
* The project depends on an undocumented Grok Bot behavior. Treat it as unsupported.

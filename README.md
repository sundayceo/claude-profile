# claude-profile

CLI for managing multiple Claude Code profiles.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/sundayceo/claude-profile/main/install.sh | bash
```

## Quick Start

Create a profile:

```bash
claude-profile --create work
```

List available profiles:

```bash
claude-profile --list
```

Select the profile used by default:

```bash
claude-profile --use work
```

Then launch Claude Code with the active profile:

```bash
claude-profile
```

You can also select the active profile interactively:

```bash
claude-profile --use
```

Launch a different profile once without changing the active profile:

```bash
claude-profile --profile personal
```

The short form is `claude-profile -P personal`. Add Claude arguments after
`--`, for example:

```bash
claude-profile -P personal -- --model opus
```

Repair shared configuration symlinks:

```bash
claude-profile --repair --all
```

## Command Reference

Running `claude-profile` without arguments launches Claude Code with the active
profile. If no profile has been selected, it uses `default`.

| Short | Long | Description |
|---|---|---|
| `-c` | `--create <name>` | Create a custom profile. |
| `-d` | `--delete <name>` | Delete a custom profile after confirmation. |
| `-l` | `--list` | List profiles; `*` marks the active profile. |
| `-u` | `--use [name]` | Save the active profile and exit. |
| `-P` | `--profile <name>` | Launch one session without changing the active profile. |
| `-p` | `--path <name>` | Print a profile's configuration directory. |
| `-r` | `--repair <name>` | Repair shared links for one custom profile. |
| `-a` | `--all` | Use with repair to repair every custom profile. |
| `-V` | `--version` | Print the installed version and releases URL. |
| `-h` | `--help` | Show command help. |
| `-S` | `--skip-version-check` | Skip the update check for one invocation. |

Use repair-all with either long or short forms:

```bash
claude-profile --repair --all
claude-profile -r -a
```

## Version and Updates

Show the installed version and the GitHub releases page:

```bash
claude-profile --version
```

On interactive invocations, `claude-profile` checks whether GitHub has a newer
release. When an update is available, choose `o` to open the release page, `u`
to install it, or `l` to be reminded again in 24 hours. Network failures never
block the requested command.

Skip the check for a single invocation by placing `--skip-version-check`
anywhere before the `--` argument boundary:

```bash
claude-profile --use work --skip-version-check
claude-profile --profile personal --skip-version-check
```

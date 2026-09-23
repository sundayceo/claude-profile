# CLI Help and Shortcuts Design

## Goal

Make every `claude-profile` command discoverable, give each command a short alias, explain bare invocation, mark the active profile in list output, and release the result as `v0.3.0`.

## Command Interface

The CLI will support these equivalent long and short forms:

| Short | Long | Behavior |
|---|---|---|
| `-c` | `--create <name>` | Create a custom profile. |
| `-d` | `--delete <name>` | Delete a custom profile after confirmation. |
| `-l` | `--list` | List profiles and mark the active one with `*`. |
| `-u` | `--use [name]` | Save the active profile and exit; omit the name to choose interactively. |
| `-P` | `--profile <name>` | Launch one session with a profile without changing the active profile. |
| `-p` | `--path <name>` | Print a profile's configuration directory. |
| `-r` | `--repair <name>` | Repair shared configuration links for one profile. |
| `-a` | `--all` | Used with repair to repair every custom profile. |
| `-V` | `--version` | Print the installed version and releases URL. |
| `-h` | `--help` | Show help. |
| `-S` | `--skip-version-check` | Skip the update check for one invocation when placed before `--`. |

Running `claude-profile` without arguments launches Claude with the active profile, falling back to `default` when no valid saved profile exists. Arguments after `--` remain Claude arguments and are never interpreted as `claude-profile` aliases.

## Help Output

Help will use separate `Usage`, `No arguments`, `Commands`, `Global options`, and `Profiles` sections. Every command row will include both forms, its arguments, and a plain-language description. The no-arguments section will explicitly explain that bare invocation launches the saved active profile or `default`.

## Profile List

`--list` and `-l` will add an `ACTIVE` marker column before the existing columns. The active profile row contains `*`; all other rows contain a blank marker. The resolved active profile uses the existing fallback rules, so malformed or stale saved state marks `default`.

## Verification and Release

Integration tests will exercise every short alias against the real CLI with isolated profile directories and fake external commands. Tests will assert the descriptive help sections, bare-invocation explanation, active marker for both default and custom profiles, global `-S` parsing before `--`, and `-r -a`. Existing long-form and update tests must remain green. The executable version becomes `0.3.0`, then the release script publishes tag `v0.3.0` with the binary and checksum after merge.

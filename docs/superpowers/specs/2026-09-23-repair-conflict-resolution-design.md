# Repair Conflict Resolution Design

## Goal

Make repair deterministic when a custom profile contains a real file or
directory where a shared symlink should exist, while letting users inspect and
choose which copy becomes canonical.

## Interface

Repair accepts `--force` and `-f` before or after its target:

```text
claude-profile --repair work --force
claude-profile --repair --force work
claude-profile --repair --all --force
claude-profile -r -f -a
```

Help documents both forms. This new backward-compatible capability increments
the minor version from 0.3.1 to 0.4.0.

## Normal repair

For each conflicting `settings.json`, `keybindings.json`, `skills`, `agents`,
or `commands` item, repair displays a unified recursive diff. If both copies
are identical, repair keeps the default copy, backs up the profile copy, and
creates the symlink without prompting.

When copies differ, repair asks the user to choose:

- `d`: keep the default copy as canonical.
- `p`: promote the profile copy to the default configuration and make it
  canonical.
- `s`: leave the conflict unchanged.

An empty or invalid response redisplays the choices. If no terminal is
available, the conflict is skipped with instructions to use `--force`.

## Forced repair

`--force` chooses the default copy for every conflict without showing a diff or
prompting. It backs up the profile copy and replaces it with a symlink.

## Data safety

Every displaced file or directory is moved to a sibling path ending in
`.claude-profile-backup`. Existing backups are never overwritten; numeric
suffixes select the next free name. Choosing the profile copy first backs up
the default copy, moves the profile copy into the default location, then creates
the profile symlink.

## Verification

Integration tests cover flag ordering and aliases, forced default selection,
normal default/profile/skip choices, displayed diffs, identical copies, and
backup preservation for files and directories.

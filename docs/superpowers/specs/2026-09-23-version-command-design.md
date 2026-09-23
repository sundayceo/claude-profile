# Version Command and Update Reminder Design

## Goal

Expose the installed `claude-profile` version through the CLI, advance the project from `0.1.0` to `0.2.0`, and notify interactive users when GitHub has a newer release.

## Behavior

- `claude-profile --version` prints `claude-profile 0.2.0` and the releases-page URL on separate lines, then exits successfully.
- `claude-profile -V` behaves identically.
- The releases-page URL is `https://github.com/sundayceo/claude-profile/releases`.
- `claude-profile --help` lists `--version`, `-V`, the update-check bypass, and active-profile commands.

## Active Profile Behavior

`claude-profile --use <name>` validates and saves the named profile as active, then exits without launching Claude. With no name, `--use` opens the existing interactive picker, saves the selection, and exits. The active profile name is stored in `$HOME/.claude-custom-profiles/.active-profile`.

Running `claude-profile` without a command launches Claude using the saved active profile. If the state file is absent, malformed, or names a profile that no longer exists, the CLI safely uses `default`.

`claude-profile --profile <name>` and `claude-profile -P <name>` launch Claude once with the requested profile without changing the saved selection. Arguments following `--` are passed to Claude. Deleting the active profile resets the stored selection to `default`.

## Update Check

Before dispatching a command, each interactive invocation follows GitHub's latest-release redirect with a short network timeout and extracts its version tag. Network errors, missing tools, malformed responses, and versions that cannot be compared fail silently so the requested command remains available offline.

When a newer version exists, the CLI displays the installed and latest versions and offers three single-key choices:

- `o` opens the GitHub releases page with the macOS `open` command and continues the original command.
- `u` runs the repository's official installer, then restarts the original command with the newly installed executable.
- `l` writes a snooze deadline under `${XDG_CACHE_HOME:-$HOME/.cache}/claude-profile/` and continues the original command. Checks remain suppressed for 24 hours.

The prompt only appears when standard input and standard error are attached to a terminal. Non-interactive execution skips the update check and never blocks for input.

`--skip-version-check` is a global modifier accepted anywhere before a `--` argument boundary. For example, both `claude-profile --skip-version-check --use work` and `claude-profile --use work --skip-version-check` suppress all network access and update prompting for that invocation. The parser removes the modifier before dispatch. Arguments after `--` belong to Claude and are never consumed as global modifiers.

## Implementation Structure

Keep the version in the existing `VERSION` constant at the top of `claude-profile`. Small functions will handle semantic-version comparison, GitHub release lookup, snooze state, user prompting, active-profile persistence, and command parsing. Global argument parsing will remove the optional skip modifier before the `--` boundary, then update checking will run before command dispatch. Add version and one-off profile branches, change `--use` to save without launching, and make empty dispatch launch the saved profile.

## Verification

Add shell tests that execute the real CLI while replacing external commands through `PATH`. Tests will cover both version flags, saved/default/one-off profile selection, deletion fallback, no notice for the current version, an available-update prompt, each prompt action, the 24-hour snooze, skip-modifier placement and boundary handling, offline behavior, and non-interactive execution. No test will access the network, open a browser, or install a binary. Run the suite with shell syntax validation and existing smoke checks. The release script will continue to read the same `VERSION` constant, so `./scripts/release 0.2.0` will validate against the executable when a release is created.

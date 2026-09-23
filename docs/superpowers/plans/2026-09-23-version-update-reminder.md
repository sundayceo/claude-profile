# Version Command and Update Reminder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add version reporting, persistent active-profile selection, one-off profile sessions, and a skippable interactive GitHub release reminder while bumping the CLI to `0.2.0`.

**Architecture:** Keep the single-file Bash CLI and its existing `VERSION` source of truth. Add focused functions for argument parsing, active-profile state, semantic-version comparison, release discovery, snooze persistence, prompting, and update installation; call them from a new `main` function. Exercise the public CLI through a dependency-free shell test harness, substituting external programs through `PATH` and using a pseudo-terminal only for interactive cases.

**Tech Stack:** Bash 3.2-compatible shell, `curl`, macOS `open`, POSIX utilities, shell integration tests.

---

### Task 1: Version command

**Files:**
- Create: `tests/cli_test.sh`
- Modify: `claude-profile:2-35,281-331`

- [ ] **Step 1: Write the failing version tests**

Create a shell test harness that runs `claude-profile --version` and `claude-profile -V`, requiring this exact output from each:

```text
claude-profile 0.2.0
Releases: https://github.com/sundayceo/claude-profile/releases
```

Also assert that `--help` contains `claude-profile --version | -V`.

- [ ] **Step 2: Verify the tests fail**

Run: `bash tests/cli_test.sh`
Expected: FAIL because `--version` is unknown and the executable still reports version `0.1.0` internally.

- [ ] **Step 3: Implement the minimal version behavior**

Set `VERSION="0.2.0"`, add `RELEASES_URL`, add this function, document the flags in `usage`, and dispatch both flags:

```bash
show_version() {
  printf 'claude-profile %s\n' "$VERSION"
  printf 'Releases: %s\n' "$RELEASES_URL"
}

--version|-V)
  show_version
  ;;
```

- [ ] **Step 4: Verify the version tests pass**

Run: `bash tests/cli_test.sh`
Expected: PASS for long flag, short flag, and help output.

### Task 2: Persistent and one-off profile selection

**Files:**
- Modify: `tests/cli_test.sh`
- Modify: `claude-profile`

- [ ] **Step 1: Write failing profile-selection tests**

Use temporary `HOME` and fake `claude` executables to assert that bare `claude-profile` launches `default` when no state exists, `--use work` writes `work` to `.claude-custom-profiles/.active-profile` without launching, a later bare invocation launches `work`, and `--profile work` plus `-P work` launch one-off sessions without changing the state file. Assert arguments after `--` reach the fake Claude executable.

- [ ] **Step 2: Verify the profile tests fail**

Run: `bash tests/cli_test.sh`
Expected: FAIL because bare execution shows help, `--use` launches immediately, and `--profile` is unknown.

- [ ] **Step 3: Implement active-profile state and dispatch**

Add `ACTIVE_PROFILE_FILE="$PROFILES_ROOT/.active-profile"`, plus `active_profile`, `set_active_profile`, and `select_active_profile`. Change `--use` to select, validate, persist atomically, print the new active profile, and exit. Add `--profile|-P` for one-off launching. Change empty dispatch to launch `active_profile`; invalid saved state falls back to `default`. When `--delete` removes the active profile, write `default`.

- [ ] **Step 4: Verify profile-selection tests pass**

Run: `bash tests/cli_test.sh`
Expected: PASS for default, saved, one-off, argument forwarding, and deletion fallback behavior.

### Task 3: Release discovery and bypass

**Files:**
- Modify: `tests/cli_test.sh`
- Modify: `claude-profile`

- [ ] **Step 1: Write failing release-check tests**

Add a fake `curl` executable through a temporary `PATH`. It records calls and returns either a latest-release redirect such as `https://github.com/sundayceo/claude-profile/releases/tag/v0.3.0` or a failure. Assert that semantic comparison recognizes `0.3.0` as newer than `0.2.0`, rejects equal/older/malformed versions, offline lookup does not fail the command, and these invocations never call `curl`:

```bash
claude-profile --skip-version-check --version
claude-profile --version --skip-version-check
printf '' | claude-profile --version
```

Also assert that `--skip-version-check` after a `--` boundary is forwarded to Claude rather than consumed.

- [ ] **Step 2: Verify the new tests fail**

Run: `bash tests/cli_test.sh`
Expected: FAIL because release discovery and `--skip-version-check` do not exist.

- [ ] **Step 3: Implement discovery, comparison, and prefix bypass**

Add functions with these contracts:

```bash
is_newer_version <candidate> <installed>
latest_version
should_check_for_update
```

`latest_version` uses `curl -fsSIL --connect-timeout 1 --max-time 2 -o /dev/null -w '%{url_effective}' "$RELEASES_URL/latest"`, strips a leading `v`, and accepts only three numeric components. `is_newer_version` compares those components numerically without GNU-only `sort -V`. `should_check_for_update` requires terminal stdin and stderr. At the start of `main`, scan arguments up to `--`, remove every `--skip-version-check` modifier while preserving order, and suppress the check for that invocation.

- [ ] **Step 4: Verify discovery tests pass**

Run: `bash tests/cli_test.sh`
Expected: PASS with no real network access.

### Task 4: Interactive choices and snooze

**Files:**
- Modify: `tests/cli_test.sh`
- Modify: `claude-profile`

- [ ] **Step 1: Write failing interactive tests**

Use the system pseudo-terminal runner to feed `o`, `u`, and `l` to the real CLI with fake `curl`, `open`, and `claude-profile` executables in `PATH`. Assert:

```text
claude-profile 0.2.0 → 0.3.0 available
[o] Open release page
[u] Update now
[l] Remind me later (24 hours)
```

For `o`, require `open` to receive the releases URL and the original command to continue. For `u`, make the installer response a harmless script, require the installer to run, and require the updated `claude-profile` shim to receive `--skip-version-check` plus the original arguments. For `l`, set `XDG_CACHE_HOME` to a temporary directory, require a numeric future deadline in `claude-profile/version-check-snooze-until`, and require a second invocation to skip `curl`.

- [ ] **Step 2: Verify interactive tests fail**

Run: `bash tests/cli_test.sh`
Expected: FAIL because the update prompt and actions are missing.

- [ ] **Step 3: Implement the prompt and actions**

Add `snooze_file`, `is_snoozed`, `snooze_updates`, `install_update`, and `check_for_update`. Read one key from `/dev/tty`; `o` calls `open "$RELEASES_URL"`, `u` downloads `https://raw.githubusercontent.com/sundayceo/claude-profile/main/install.sh` into a temporary file, runs it with Bash, removes it, then executes `claude-profile --skip-version-check "$@"`; `l` writes the current epoch plus 86,400 seconds. Unknown keys repeat the prompt. Failures print a concise error and continue the original command.

- [ ] **Step 4: Verify all integration tests pass**

Run: `bash tests/cli_test.sh`
Expected: PASS for version output, bypass, offline behavior, all choices, snoozing, and command continuation.

### Task 5: Documentation and final verification

**Files:**
- Modify: `README.md`
- Modify: `tests/cli_test.sh` if verification exposes a missing assertion

- [ ] **Step 1: Document version and update controls**

Add a concise README section showing:

```bash
claude-profile --version
claude-profile --use work
claude-profile --profile personal
claude-profile --skip-version-check --use work
```

Explain persistent active profiles, one-off sessions, the `o`, `u`, and `l` actions, and the 24-hour snooze.

- [ ] **Step 2: Run syntax and behavior verification**

Run: `bash -n claude-profile install.sh scripts/release tests/cli_test.sh`
Expected: exit 0 with no output.

Run: `bash tests/cli_test.sh`
Expected: all tests pass with no network, browser, or installation side effects.

Run: `./claude-profile --skip-version-check --version`
Expected:

```text
claude-profile 0.2.0
Releases: https://github.com/sundayceo/claude-profile/releases
```

Run: `./scripts/release 0.1.0`
Expected: exit 1 with `Version mismatch: script=0.2.0 requested=0.1.0` before any release mutation.

# CLI Help and Shortcuts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `v0.3.0` with descriptive help, a short alias for every command, documented bare invocation, and an active-profile marker in list output.

**Architecture:** Preserve the single-file Bash CLI and extend its existing dispatch aliases. Keep help text in `usage`, calculate the active profile once in `list_profiles`, and verify public behavior through the existing isolated integration suite.

**Tech Stack:** Bash 3.2-compatible shell, shell integration tests, GitHub release script.

---

### Task 1: Descriptive help and version bump

**Files:**
- Modify: `claude-profile`
- Modify: `tests/cli_test.sh`

- [ ] **Step 1: Add failing help tests**

Assert `--help` contains `No arguments:`, explains that bare invocation launches the active profile, contains `Commands:` and `Global options:`, and includes every mapping: `-c, --create`, `-d, --delete`, `-l, --list`, `-u, --use`, `-P, --profile`, `-p, --path`, `-r, --repair`, `-a, --all`, `-V, --version`, `-h, --help`, and `-S, --skip-version-check`. Assert `--version` reports `0.3.0`.

- [ ] **Step 2: Run the suite and confirm the new assertions fail**

Run: `bash tests/cli_test.sh`
Expected: FAIL because help lacks descriptions and the executable reports `0.2.0`.

- [ ] **Step 3: Replace usage text and bump the version**

Set `VERSION="0.3.0"`. Format `usage` with `Usage`, `No arguments`, `Commands`, `Global options`, and `Profiles` sections. Give every row its short and long forms plus a one-sentence description.

- [ ] **Step 4: Run the suite and confirm help tests pass**

Run: `bash tests/cli_test.sh`
Expected: help and version assertions pass while shortcut tests still fail.

### Task 2: Command aliases

**Files:**
- Modify: `claude-profile`
- Modify: `tests/cli_test.sh`

- [ ] **Step 1: Add failing integration tests for all aliases**

Using temporary `HOME` directories and the existing fake Claude executable, exercise `-c`, `-d`, `-l`, `-u`, `-P`, `-p`, `-r`, `-r -a`, `-V`, `-h`, and `-S`. Assert each has the same state, output, or process behavior as its long form. Assert `-S` is removed anywhere before `--` and preserved after `--`.

- [ ] **Step 2: Run the suite and confirm alias failures**

Run: `bash tests/cli_test.sh`
Expected: FAIL on aliases not already implemented.

- [ ] **Step 3: Add aliases to parsing and dispatch**

Treat `-S` like `--skip-version-check` before the argument boundary. Extend dispatch patterns to `--create|-c`, `--delete|-d`, `--list|-l`, `--path|-p`, `--repair|-r`, `--use|-u`, `--profile|-P`, `--help|-h`, and `--version|-V`. Accept `--all|-a` only as the repair target.

- [ ] **Step 4: Run the suite and confirm alias tests pass**

Run: `bash tests/cli_test.sh`
Expected: all long and short command tests pass.

### Task 3: Active list marker

**Files:**
- Modify: `claude-profile`
- Modify: `tests/cli_test.sh`

- [ ] **Step 1: Add failing list-marker tests**

Assert the list header begins with `ACTIVE`, the default row begins with `*` when no custom selection is saved, a saved custom profile row begins with `*`, and the default row becomes unmarked. Run the same check through `-l`.

- [ ] **Step 2: Run the suite and confirm marker assertions fail**

Run: `bash tests/cli_test.sh`
Expected: FAIL because list output has no marker column.

- [ ] **Step 3: Render the active marker**

Resolve `active="$(active_profile)"` once. Print an `ACTIVE` header and pass `*` for the matching default or custom row and an empty string for all other rows.

- [ ] **Step 4: Run the suite and confirm marker tests pass**

Run: `bash tests/cli_test.sh`
Expected: all CLI tests pass.

### Task 4: Documentation, review, and release

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Document aliases and list marker**

Add a command-reference table matching `--help`, explain bare invocation, and state that `*` marks the active profile.

- [ ] **Step 2: Run final local verification**

Run: `bash -n claude-profile install.sh scripts/release tests/cli_test.sh tests/fixtures/bin/* tests/fixtures/updated-claude-profile`
Expected: exit 0.

Run: `bash tests/cli_test.sh`
Expected: `All CLI tests passed.`

Run: `./claude-profile -S -V`
Expected: `claude-profile 0.3.0` and the releases URL.

Run: `./scripts/release 0.2.0`
Expected: version mismatch before any release mutation.

- [ ] **Step 3: Review, merge, and publish**

Review the complete diff against the design, merge to `main`, rerun the suite on merged `main`, then run `./scripts/release 0.3.0`. Verify GitHub reports `v0.3.0` as the latest non-draft release with `claude-profile` and `claude-profile.sha256` assets.

# Repair Conflict Resolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add safe interactive and forced conflict resolution to profile repair.

**Architecture:** Parse repair arguments into a target and force flag, then route every conflicting shared item through one resolver. The resolver displays `diff -ru`, obtains a choice when needed, and uses collision-safe sibling backups before establishing the canonical symlink.

**Tech Stack:** Bash 3.2, Expect integration fixtures, GitHub release script

---

### Task 1: Lock down CLI parsing and help

**Files:**
- Modify: `claude-profile`
- Modify: `tests/cli_test.sh`

- [ ] Add failing assertions for `--force`/`-f` help and flag ordering.
- [ ] Run `bash tests/cli_test.sh` and confirm the parsing assertions fail.
- [ ] Add repair argument parsing for one target, `--all`/`-a`, and `--force`/`-f` in either order.
- [ ] Run the full CLI suite and confirm the parsing assertions pass.

### Task 2: Add conflict selection

**Files:**
- Modify: `claude-profile`
- Modify: `tests/cli_test.sh`
- Modify: `tests/fixtures/run_interactive.exp`

- [ ] Add failing integration cases for displayed diffs and default, profile,
  skip, identical, and forced outcomes.
- [ ] Run the suite and confirm failures reflect the current automatic-default
  behavior.
- [ ] Add collision-safe backup, diff, prompt, and canonical-copy helpers.
- [ ] Route repair conflicts through the resolver and run the suite until all
  cases pass.

### Task 3: Document and release

**Files:**
- Modify: `README.md`
- Modify: `claude-profile`
- Modify: `tests/cli_test.sh`
- Modify: `tests/fixtures/bin/curl`

- [ ] Document repair conflict choices and forced operation.
- [ ] Bump version from 0.3.1 to 0.4.0 and update version fixtures.
- [ ] Run Bash syntax checks, `bash tests/cli_test.sh`, `git diff --check`, and
  `./claude-profile -S -V`.
- [ ] Commit, push `main`, tag v0.4.0, and publish the release assets.

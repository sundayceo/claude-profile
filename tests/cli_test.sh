#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/claude-profile"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

failures=0

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: %s\nexpected:\n%s\nactual:\n%s\n' \
      "$message" "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "$haystack" != *"$needle"* ]]; then
    printf 'FAIL: %s\nmissing: %s\nactual:\n%s\n' \
      "$message" "$needle" "$haystack" >&2
    failures=$((failures + 1))
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    printf 'FAIL: %s\nunexpected: %s\nactual:\n%s\n' \
      "$message" "$needle" "$haystack" >&2
    failures=$((failures + 1))
  fi
}

assert_occurrences() {
  local haystack="$1"
  local needle="$2"
  local expected="$3"
  local message="$4"
  local remainder="$haystack"
  local actual=0

  while [[ "$remainder" == *"$needle"* ]]; do
    remainder="${remainder#*"$needle"}"
    actual=$((actual + 1))
  done

  if [[ "$actual" -ne "$expected" ]]; then
    printf 'FAIL: %s\nexpected occurrences: %s\nactual occurrences: %s\n' \
      "$message" "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

assert_file_eq() {
  local expected="$1"
  local path="$2"
  local message="$3"
  local actual='<missing>'

  if [[ -f "$path" ]]; then
    actual="$(cat "$path")"
  fi

  assert_eq "$expected" "$actual" "$message"
}

assert_file_missing() {
  local path="$1"
  local message="$2"

  if [[ -e "$path" ]]; then
    printf 'FAIL: %s\nunexpected file: %s\n' "$message" "$path" >&2
    failures=$((failures + 1))
  fi
}

assert_symlink_to() {
  local expected="$1"
  local path="$2"
  local message="$3"

  if [[ ! -L "$path" ]]; then
    printf 'FAIL: %s\nnot a symlink: %s\n' "$message" "$path" >&2
    failures=$((failures + 1))
    return
  fi

  assert_eq "$expected" "$(readlink "$path")" "$message"
}

assert_dir_exists() {
  local path="$1"
  local message="$2"

  if [[ ! -d "$path" ]]; then
    printf 'FAIL: %s\nmissing directory: %s\n' "$message" "$path" >&2
    failures=$((failures + 1))
  fi
}

assert_status() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$actual" -ne "$expected" ]]; then
    printf 'FAIL: %s\nexpected status: %s\nactual status: %s\n' \
      "$message" "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

run_interactive() {
  local input="$1"
  local home="$2"
  local cache="$3"
  local curl_mode="$4"
  shift 4

  mkdir -p "$home"
  [[ -e "$cache" ]] || mkdir -p "$cache"
  HOME="$home" \
    XDG_CACHE_HOME="$cache" \
    PATH="$fake_bin:$PATH" \
    CURL_TEST_LOG="$curl_log" \
    CURL_TEST_MODE="$curl_mode" \
    OPEN_TEST_LOG="$open_log" \
    INSTALL_TEST_LOG="$install_log" \
    REEXEC_TEST_LOG="$reexec_log" \
    INSTALLED_REEXEC_TEST_LOG="$installed_reexec_log" \
    UPDATED_CLI_FIXTURE="$ROOT_DIR/tests/fixtures/updated-claude-profile" \
    expect "$ROOT_DIR/tests/fixtures/run_interactive.exp" \
      "$input" "$CLI" "$@" 2>&1
}

run_repair_interactive() {
  local choice="$1"
  local home="$2"
  shift 2

  HOME="$home" \
    PATH="$fake_bin:$PATH" \
    expect "$ROOT_DIR/tests/fixtures/run_repair_interactive.exp" \
      "$choice" "$CLI" --skip-version-check "$@" 2>&1
}

expected_version='claude-profile 0.4.1
Releases: https://github.com/sundayceo/claude-profile/releases'

home="$TEST_ROOT/version-home"
mkdir -p "$home"

output="$(HOME="$home" "$CLI" --version 2>&1 || true)"
assert_eq "$expected_version" "$output" '--version prints version and releases URL'

output="$(HOME="$home" "$CLI" -V 2>&1 || true)"
assert_eq "$expected_version" "$output" '-V prints version and releases URL'

output="$(HOME="$home" "$CLI" --help 2>&1 || true)"
assert_contains "$output" 'No arguments:' '--help has a no-arguments section'
assert_contains "$output" 'Launch Claude Code with the active profile' \
  '--help explains bare invocation'
assert_contains "$output" 'Commands:' '--help has a commands section'
assert_contains "$output" 'Global options:' '--help has a global-options section'
assert_contains "$output" '-c, --create <name>' '--help describes create aliases'
assert_contains "$output" '-d, --delete <name>' '--help describes delete aliases'
assert_contains "$output" '-l, --list' '--help describes list aliases'
assert_contains "$output" '-u, --use [name]' '--help describes use aliases'
assert_contains "$output" '-P, --profile <name>' '--help describes profile aliases'
assert_contains "$output" '-p, --path <name>' '--help describes path aliases'
assert_contains "$output" '-r, --repair <name>' '--help describes repair aliases'
assert_contains "$output" '-a, --all' '--help describes repair-all aliases'
assert_contains "$output" '-f, --force' '--help describes force aliases'
assert_contains "$output" '-V, --version' '--help describes version aliases'
assert_contains "$output" '-h, --help' '--help describes help aliases'
assert_contains "$output" '-S, --skip-version-check' '--help describes skip aliases'
assert_contains "$output" 'Create a custom profile.' '--help explains create'
assert_contains "$output" 'Mark the active profile with *.' '--help explains list output'

fake_bin="$ROOT_DIR/tests/fixtures/bin"
chmod +x "$fake_bin/claude" "$fake_bin/curl" \
  "$fake_bin/open" "$fake_bin/claude-profile" \
  "$ROOT_DIR/tests/fixtures/run_interactive.exp" \
  "$ROOT_DIR/tests/fixtures/updated-claude-profile"

home="$TEST_ROOT/profile-home"
log="$TEST_ROOT/claude.log"
mkdir -p "$home/.claude" "$home/.claude-custom-profiles/work"

: > "$log"
HOME="$home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$log" \
  "$CLI" >/dev/null 2>&1 || true
assert_file_eq $'config=<unset>\nargs=' "$log" \
  'bare invocation launches the default profile when no selection exists'

: > "$log"
HOME="$home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$log" \
  "$CLI" --use work >/dev/null 2>&1 || true
assert_file_eq 'work' "$home/.claude-custom-profiles/.active-profile" \
  '--use saves the active profile'
assert_file_eq '' "$log" '--use saves without launching Claude'

fresh_home="$TEST_ROOT/fresh-home"
fresh_log="$TEST_ROOT/fresh-claude.log"
mkdir -p "$fresh_home"
: > "$fresh_log"
HOME="$fresh_home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$fresh_log" \
  "$CLI" >/dev/null 2>&1 || true
assert_file_eq $'config=<unset>\nargs=' "$fresh_log" \
  'bare invocation launches default before its config directory exists'

: > "$log"
HOME="$home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$log" \
  "$CLI" >/dev/null 2>&1 || true
assert_file_eq "config=$home/.claude-custom-profiles/work
args=" "$log" 'bare invocation launches the saved active profile'

: > "$log"
HOME="$home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$log" \
  "$CLI" -- --dangerously-skip-permission >/dev/null 2>&1 || true
assert_file_eq "config=$home/.claude-custom-profiles/work
args=<--dangerously-skip-permission>" "$log" \
  'a bare -- boundary forwards Claude arguments to the active profile'

printf '%s\n' default > "$home/.claude-custom-profiles/.active-profile"
: > "$log"
HOME="$home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$log" \
  "$CLI" --profile work -- --model opus >/dev/null 2>&1 || true
assert_file_eq "config=$home/.claude-custom-profiles/work
args=<--model><opus>" "$log" '--profile launches a one-off profile with Claude arguments'
assert_file_eq 'default' "$home/.claude-custom-profiles/.active-profile" \
  '--profile does not change the active profile'

: > "$log"
HOME="$home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$log" \
  "$CLI" -P work >/dev/null 2>&1 || true
assert_file_eq "config=$home/.claude-custom-profiles/work
args=" "$log" '-P launches a one-off profile'

bash -c 'source "$1"; is_newer_version 0.3.0 0.2.0' _ "$CLI" 2>/dev/null
assert_status 0 "$?" 'a greater semantic version is newer'

bash -c 'source "$1"; is_newer_version 0.2.0 0.2.0' _ "$CLI" 2>/dev/null
assert_status 1 "$?" 'an equal semantic version is not newer'

bash -c 'source "$1"; is_newer_version 0.1.9 0.2.0' _ "$CLI" 2>/dev/null
assert_status 1 "$?" 'an older semantic version is not newer'

bash -c 'source "$1"; is_newer_version latest 0.2.0' _ "$CLI" 2>/dev/null
assert_status 1 "$?" 'a malformed semantic version is rejected'

curl_log="$TEST_ROOT/curl.log"
: > "$curl_log"
output="$(PATH="$fake_bin:$PATH" CURL_TEST_LOG="$curl_log" CURL_TEST_MODE=latest \
  bash -c 'source "$1"; latest_version' _ "$CLI" 2>/dev/null || true)"
assert_eq '0.5.0' "$output" 'latest_version extracts the redirected release tag'

output="$(PATH="$fake_bin:$PATH" CURL_TEST_MODE=offline \
  bash -c 'source "$1"; latest_version' _ "$CLI" 2>/dev/null || true)"
assert_eq '' "$output" 'latest_version is silent when offline'

output="$(bash -c '
  source "$1"
  parse_global_args --use work --skip-version-check
  printf "%s|" "$SKIP_VERSION_CHECK"
  printf "<%s>" "${PARSED_ARGS[@]}"
' _ "$CLI" 2>/dev/null || true)"
assert_eq '1|<--use><work>' "$output" \
  '--skip-version-check is removed after the command'

output="$(bash -c '
  source "$1"
  parse_global_args --profile work -- --skip-version-check
  printf "%s|" "$SKIP_VERSION_CHECK"
  printf "<%s>" "${PARSED_ARGS[@]}"
' _ "$CLI" 2>/dev/null || true)"
assert_eq '0|<--profile><work><--><--skip-version-check>' "$output" \
  '--skip-version-check is preserved after the argument boundary'

curl_log="$TEST_ROOT/interactive-curl.log"
open_log="$TEST_ROOT/open.log"
install_log="$TEST_ROOT/install.log"
reexec_log="$TEST_ROOT/reexec.log"
installed_reexec_log="$TEST_ROOT/installed-reexec.log"
: > "$curl_log"
: > "$open_log"
: > "$reexec_log"
: > "$installed_reexec_log"

open_home="$TEST_ROOT/open-home"
open_cache="$TEST_ROOT/open-cache"
output="$(run_interactive ol "$open_home" "$open_cache" latest --version)"
interactive_status=$?
assert_status 0 "$interactive_status" 'o waits for l before continuing'
assert_contains "$output" 'claude-profile 0.4.1 → 0.5.0 available' \
  'interactive invocation announces a newer version'
assert_occurrences "$output" '[o] Open release page' 2 \
  'o redisplays the update prompt'
assert_contains "$output" '[u] Update now' 'update prompt offers installation'
assert_contains "$output" '[l] Remind me later (24 hours)' 'update prompt offers snoozing'
assert_file_eq 'https://github.com/sundayceo/claude-profile/releases' "$open_log" \
  'o opens the releases page'
assert_contains "$output" 'Releases: https://github.com/sundayceo/claude-profile/releases' \
  'l continues the original command after o'

: > "$curl_log"
interactive_home="$TEST_ROOT/interactive-home"
interactive_cache="$TEST_ROOT/interactive-cache"
output="$(run_interactive l "$interactive_home" "$interactive_cache" latest --version || true)"
snooze_file="$interactive_cache/claude-profile/version-check-snooze-until"
if [[ ! -f "$snooze_file" ]] || ! [[ "$(cat "$snooze_file" 2>/dev/null)" =~ ^[0-9]+$ ]]; then
  printf 'FAIL: l stores a numeric snooze deadline\n' >&2
  failures=$((failures + 1))
else
  snooze_deadline="$(cat "$snooze_file")"
  expected_deadline=$(( $(date +%s) + 86400 ))
  if (( snooze_deadline < expected_deadline - 10 || snooze_deadline > expected_deadline + 10 )); then
    printf 'FAIL: l stores a deadline approximately 24 hours ahead\n' >&2
    failures=$((failures + 1))
  fi
fi

: > "$curl_log"
output="$(run_interactive '' "$interactive_home" "$interactive_cache" latest --version || true)"
assert_file_eq '' "$curl_log" 'a snoozed invocation performs no release request'
assert_contains "$output" 'claude-profile 0.4.1' 'a snoozed invocation continues'

update_home="$TEST_ROOT/update-home"
update_cache="$TEST_ROOT/update-cache"
: > "$curl_log"
: > "$reexec_log"
: > "$installed_reexec_log"
assert_file_missing "$install_log" 'installer has not run before choosing u'
output="$(run_interactive u "$update_home" "$update_cache" latest --version || true)"
assert_file_eq 'installed' "$install_log" 'u runs the official installer'
assert_file_eq 'args=<--skip-version-check><--version>' "$installed_reexec_log" \
  'u restarts the binary written by the installer'
assert_file_eq '' "$reexec_log" 'u does not restart an older binary from PATH'

blocked_cache="$TEST_ROOT/blocked-cache"
: > "$blocked_cache"
blocked_home="$TEST_ROOT/blocked-home"
output="$(run_interactive l "$blocked_home" "$blocked_cache" latest --version)"
blocked_status=$?
assert_status 0 "$blocked_status" 'an unwritable snooze cache does not fail the command'
assert_contains "$output" 'Releases: https://github.com/sundayceo/claude-profile/releases' \
  'an unwritable snooze cache continues the original command'

skip_home="$TEST_ROOT/skip-home"
skip_cache="$TEST_ROOT/skip-cache"
: > "$curl_log"
output="$(run_interactive '' "$skip_home" "$skip_cache" latest \
  --version --skip-version-check || true)"
assert_file_eq '' "$curl_log" '--skip-version-check prevents release requests'
assert_contains "$output" 'claude-profile 0.4.1' \
  '--skip-version-check continues the original command'

offline_home="$TEST_ROOT/offline-home"
offline_cache="$TEST_ROOT/offline-cache"
output="$(run_interactive '' "$offline_home" "$offline_cache" offline --version || true)"
assert_contains "$output" 'claude-profile 0.4.1' 'offline update checks do not block commands'
assert_not_contains "$output" 'simulated network failure' \
  'offline update checks fail silently'

current_home="$TEST_ROOT/current-home"
current_cache="$TEST_ROOT/current-cache"
output="$(run_interactive '' "$current_home" "$current_cache" current --version)"
current_status=$?
assert_status 0 "$current_status" 'the current release continues successfully'
assert_not_contains "$output" 'available' 'the current release shows no update prompt'

: > "$curl_log"
HOME="$TEST_ROOT/noninteractive-home" PATH="$fake_bin:$PATH" \
  CURL_TEST_LOG="$curl_log" CURL_TEST_MODE=latest \
  "$CLI" --version >/dev/null 2>&1 || true
assert_file_eq '' "$curl_log" 'non-interactive invocations skip release requests'

delete_home="$TEST_ROOT/delete-home"
delete_log="$TEST_ROOT/delete-claude.log"
mkdir -p "$delete_home/.claude-custom-profiles/work"
HOME="$delete_home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$delete_log" \
  "$CLI" --use work >/dev/null 2>&1 || true
printf 'y\n' | HOME="$delete_home" PATH="$fake_bin:$PATH" \
  CLAUDE_TEST_LOG="$delete_log" "$CLI" --delete work >/dev/null 2>&1 || true
assert_file_eq 'default' "$delete_home/.claude-custom-profiles/.active-profile" \
  'deleting the active profile resets selection to default'
assert_file_missing "$delete_home/.claude-custom-profiles/work" \
  'deleting a profile removes its directory'

malformed_home="$TEST_ROOT/malformed-home"
malformed_log="$TEST_ROOT/malformed-claude.log"
mkdir -p "$malformed_home/.claude" "$malformed_home/.claude-custom-profiles/work"
printf 'work\nextra\n' > "$malformed_home/.claude-custom-profiles/.active-profile"
: > "$malformed_log"
HOME="$malformed_home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$malformed_log" \
  "$CLI" >/dev/null 2>&1 || true
assert_file_eq $'config=<unset>\nargs=' "$malformed_log" \
  'a malformed multiline active-profile file falls back to default'

printf 'work\n\n' > "$malformed_home/.claude-custom-profiles/.active-profile"
: > "$malformed_log"
HOME="$malformed_home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$malformed_log" \
  "$CLI" >/dev/null 2>&1 || true
assert_file_eq $'config=<unset>\nargs=' "$malformed_log" \
  'an active-profile file with a trailing blank line falls back to default'

boundary_home="$TEST_ROOT/boundary-home"
boundary_log="$TEST_ROOT/boundary-claude.log"
mkdir -p "$boundary_home/.claude" "$boundary_home/.claude-custom-profiles/work"
: > "$boundary_log"
HOME="$boundary_home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$boundary_log" \
  "$CLI" --profile work -- --skip-version-check >/dev/null 2>&1 || true
assert_file_eq "config=$boundary_home/.claude-custom-profiles/work
args=<--skip-version-check>" "$boundary_log" \
  'arguments after -- are forwarded without global parsing'

alias_home="$TEST_ROOT/alias-home"
alias_log="$TEST_ROOT/alias-claude.log"
mkdir -p "$alias_home/.claude"

HOME="$alias_home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$alias_log" \
  "$CLI" -c work >/dev/null 2>&1 || true
assert_dir_exists "$alias_home/.claude-custom-profiles/work" \
  '-c creates a custom profile'

output="$(HOME="$alias_home" "$CLI" --list 2>&1 || true)"
assert_contains "$output" 'ACTIVE' '--list labels the active marker column'
assert_contains "$output" $'*      default' \
  '--list marks default active before a profile is selected'
assert_not_contains "$output" $'*      work' \
  '--list leaves inactive custom profiles unmarked'

HOME="$alias_home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$alias_log" \
  "$CLI" -u work >/dev/null 2>&1 || true
assert_file_eq 'work' "$alias_home/.claude-custom-profiles/.active-profile" \
  '-u saves the active profile'

output="$(HOME="$alias_home" "$CLI" -l 2>&1 || true)"
assert_contains "$output" 'work' '-l lists profiles'
assert_contains "$output" $'*      work' '-l marks the saved custom profile active'
assert_not_contains "$output" $'*      default' '-l removes the marker from default'

output="$(HOME="$alias_home" "$CLI" -p work 2>&1 || true)"
assert_eq "$alias_home/.claude-custom-profiles/work" "$output" \
  '-p prints the profile path'

: > "$alias_log"
HOME="$alias_home" PATH="$fake_bin:$PATH" CLAUDE_TEST_LOG="$alias_log" \
  "$CLI" -P work -- --model opus >/dev/null 2>&1 || true
assert_file_eq "config=$alias_home/.claude-custom-profiles/work
args=<--model><opus>" "$alias_log" '-P launches a one-off profile'

output="$(HOME="$alias_home" "$CLI" -r work 2>&1 || true)"
assert_contains "$output" 'Repairing:' '-r repairs one profile'

output="$(HOME="$alias_home" "$CLI" -r -a -f 2>&1 || true)"
assert_contains "$output" 'Repairing:' '-r -a repairs all custom profiles'

repair_home="$TEST_ROOT/repair-home"
mkdir -p "$repair_home/.claude/skills" \
  "$repair_home/.claude/agents" \
  "$repair_home/.claude/commands" \
  "$repair_home/.claude-custom-profiles/work/skills"
printf '%s\n' '{"theme":"dark"}' > "$repair_home/.claude/settings.json"
printf '%s\n' '{"theme":"light"}' > \
  "$repair_home/.claude-custom-profiles/work/settings.json"
printf '%s\n' '[{"key":"ctrl+k"}]' > "$repair_home/.claude/keybindings.json"
printf '%s\n' '[{"key":"ctrl+j"}]' > \
  "$repair_home/.claude-custom-profiles/work/keybindings.json"
printf '%s\n' 'default skill' > "$repair_home/.claude/skills/default.md"
printf '%s\n' 'profile skill' > \
  "$repair_home/.claude-custom-profiles/work/skills/profile.md"

output="$(HOME="$repair_home" "$CLI" --repair --all --force 2>&1 || true)"
assert_symlink_to "$repair_home/.claude/settings.json" \
  "$repair_home/.claude-custom-profiles/work/settings.json" \
  '--repair --all syncs settings.json with the default profile'
assert_file_eq '{"theme":"light"}' \
  "$repair_home/.claude-custom-profiles/work/settings.json.claude-profile-backup" \
  '--repair --all backs up existing profile settings before syncing'
assert_contains "$output" 'backed up settings.json' \
  '--repair --all reports the settings backup'
assert_symlink_to "$repair_home/.claude/keybindings.json" \
  "$repair_home/.claude-custom-profiles/work/keybindings.json" \
  '--repair --all syncs keybindings.json with the default profile'
assert_file_eq '[{"key":"ctrl+j"}]' \
  "$repair_home/.claude-custom-profiles/work/keybindings.json.claude-profile-backup" \
  '--repair --all backs up existing profile keybindings before syncing'
assert_contains "$output" 'backed up keybindings.json' \
  '--repair --all reports the keybindings backup'
assert_symlink_to "$repair_home/.claude/skills" \
  "$repair_home/.claude-custom-profiles/work/skills" \
  '--repair --all syncs skills with the default profile'
assert_file_eq 'profile skill' \
  "$repair_home/.claude-custom-profiles/work/skills.claude-profile-backup/profile.md" \
  '--repair --all backs up existing profile skills before syncing'
assert_symlink_to "$repair_home/.claude/agents" \
  "$repair_home/.claude-custom-profiles/work/agents" \
  '--repair --all syncs agents with the default profile'
assert_symlink_to "$repair_home/.claude/commands" \
  "$repair_home/.claude-custom-profiles/work/commands" \
  '--repair --all syncs commands with the default profile'
assert_not_contains "$output" '@@' '--force does not show a diff'

force_order_home="$TEST_ROOT/force-order-home"
mkdir -p "$force_order_home/.claude" \
  "$force_order_home/.claude-custom-profiles/work"
printf '%s\n' 'default' > "$force_order_home/.claude/settings.json"
printf '%s\n' 'profile' > \
  "$force_order_home/.claude-custom-profiles/work/settings.json"
HOME="$force_order_home" "$CLI" --skip-version-check \
  --repair --force work >/dev/null 2>&1 || true
assert_symlink_to "$force_order_home/.claude/settings.json" \
  "$force_order_home/.claude-custom-profiles/work/settings.json" \
  '--force is accepted before a repair profile name'

profile_choice_home="$TEST_ROOT/profile-choice-home"
mkdir -p "$profile_choice_home/.claude" \
  "$profile_choice_home/.claude-custom-profiles/work"
printf '%s\n' '{"theme":"dark"}' > \
  "$profile_choice_home/.claude/settings.json"
printf '%s\n' '{"theme":"light"}' > \
  "$profile_choice_home/.claude-custom-profiles/work/settings.json"
output="$(run_repair_interactive p "$profile_choice_home" --repair work)"
assert_contains "$output" '-{"theme":"dark"}' \
  'normal repair shows the default side of the diff'
assert_contains "$output" '+{"theme":"light"}' \
  'normal repair shows the profile side of the diff'
assert_file_eq '{"theme":"light"}' \
  "$profile_choice_home/.claude/settings.json" \
  'p promotes the profile copy to the default configuration'
assert_file_eq '{"theme":"dark"}' \
  "$profile_choice_home/.claude/settings.json.claude-profile-backup" \
  'p backs up the displaced default copy'
assert_symlink_to "$profile_choice_home/.claude/settings.json" \
  "$profile_choice_home/.claude-custom-profiles/work/settings.json" \
  'p links the profile to its promoted copy'

default_choice_home="$TEST_ROOT/default-choice-home"
mkdir -p "$default_choice_home/.claude" \
  "$default_choice_home/.claude-custom-profiles/work"
printf '%s\n' 'default' > "$default_choice_home/.claude/settings.json"
printf '%s\n' 'profile' > \
  "$default_choice_home/.claude-custom-profiles/work/settings.json"
output="$(run_repair_interactive d "$default_choice_home" --repair work)"
assert_file_eq 'default' "$default_choice_home/.claude/settings.json" \
  'd keeps the default copy canonical'
assert_file_eq 'profile' \
  "$default_choice_home/.claude-custom-profiles/work/settings.json.claude-profile-backup" \
  'd backs up the displaced profile copy'
assert_symlink_to "$default_choice_home/.claude/settings.json" \
  "$default_choice_home/.claude-custom-profiles/work/settings.json" \
  'd links the profile to the default copy'

skip_choice_home="$TEST_ROOT/skip-choice-home"
mkdir -p "$skip_choice_home/.claude" \
  "$skip_choice_home/.claude-custom-profiles/work"
printf '%s\n' 'default' > "$skip_choice_home/.claude/keybindings.json"
printf '%s\n' 'profile' > \
  "$skip_choice_home/.claude-custom-profiles/work/keybindings.json"
output="$(run_repair_interactive s "$skip_choice_home" --repair work)"
assert_file_eq 'default' "$skip_choice_home/.claude/keybindings.json" \
  's keeps the default copy unchanged'
assert_file_eq 'profile' \
  "$skip_choice_home/.claude-custom-profiles/work/keybindings.json" \
  's keeps the profile copy unchanged'
assert_file_missing \
  "$skip_choice_home/.claude-custom-profiles/work/keybindings.json.claude-profile-backup" \
  's does not create a backup'

identical_home="$TEST_ROOT/identical-home"
mkdir -p "$identical_home/.claude" \
  "$identical_home/.claude-custom-profiles/work"
printf '%s\n' 'same' > "$identical_home/.claude/settings.json"
printf '%s\n' 'same' > \
  "$identical_home/.claude-custom-profiles/work/settings.json"
output="$(HOME="$identical_home" "$CLI" --skip-version-check \
  --repair work 2>&1 || true)"
assert_contains "$output" 'identical' \
  'normal repair does not prompt for identical copies'
assert_symlink_to "$identical_home/.claude/settings.json" \
  "$identical_home/.claude-custom-profiles/work/settings.json" \
  'normal repair links identical copies automatically'

output="$(HOME="$alias_home" "$CLI" -V 2>&1 || true)"
assert_eq "$expected_version" "$output" '-V shows the version'

output="$(HOME="$alias_home" "$CLI" -h 2>&1 || true)"
assert_contains "$output" 'Commands:' '-h shows descriptive help'

output="$(bash -c '
  source "$1"
  parse_global_args -u work -S
  printf "%s|" "$SKIP_VERSION_CHECK"
  printf "<%s>" "${PARSED_ARGS[@]}"
' _ "$CLI" 2>/dev/null || true)"
assert_eq '1|<-u><work>' "$output" '-S is removed before the argument boundary'

output="$(bash -c '
  source "$1"
  parse_global_args -P work -- -S
  printf "%s|" "$SKIP_VERSION_CHECK"
  printf "<%s>" "${PARSED_ARGS[@]}"
' _ "$CLI" 2>/dev/null || true)"
assert_eq '0|<-P><work><--><-S>' "$output" '-S is preserved after the argument boundary'

printf 'y\n' | HOME="$alias_home" PATH="$fake_bin:$PATH" \
  CLAUDE_TEST_LOG="$alias_log" "$CLI" -d work >/dev/null 2>&1 || true
assert_file_missing "$alias_home/.claude-custom-profiles/work" \
  '-d deletes a custom profile'

if (( failures > 0 )); then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi

echo 'All CLI tests passed.'

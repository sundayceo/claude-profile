# claude-profile

CLI for managing multiple Claude Code profiles.

## Installation

Install the latest release:


## Installation

Install the latest release:

```bash
mkdir -p "$HOME/bin"

curl -fsSL \
  https://github.com/sundayceo/claude-profile/releases/latest/download/claude-profile \
  -o "$HOME/bin/claude-profile"

chmod +x "$HOME/bin/claude-profile"
```

Make sure `~/bin` is on your `PATH`:

```bash
grep -Fqx 'export PATH="$HOME/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null || \
  echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"

source "$HOME/.zshrc"
```

Verify the installation:

```bash
claude-profile --version
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

Launch Claude Code with a specific profile:

```bash
claude-profile --use work
```

Launch the default Claude Code profile:

```bash
claude-profile --use default
```

Or select a profile interactively:

```bash
claude-profile --use
```

Repair shared configuration symlinks:

```bash
claude-profile --repair --all
```

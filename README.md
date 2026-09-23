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

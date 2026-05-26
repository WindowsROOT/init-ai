# init-ai

[ภาษาไทย](README-TH.md)

Bootstrap tooling for AI coding agents — install community **agent skills** into Cursor and Claude Code from one script.

## Prerequisites

- `git`
- **macOS / Linux:** `bash`
- **Windows:** Command Prompt (or `cmd.exe` in Terminal); `git` on PATH
- `npx` (Node.js) — only if you use `--method npx` or `--method all` for [mattpocock/skills](https://github.com/mattpocock/skills)

## Quickstart

**macOS / Linux:**

```bash
git clone https://github.com/YOUR_USER/init-ai.git
cd init-ai
./scripts/install-skills.sh
```

**Windows (CMD):**

```bat
git clone https://github.com/YOUR_USER/init-ai.git
cd init-ai
scripts\install-skills.cmd
```

On Windows, skills are linked with directory junctions (`mklink /J`); if that fails, the script copies the skill folder instead.

This clones three upstream repos into `~/.local/share/init-ai/skills-cache/` and symlinks shippable skills into:

- `~/.cursor/skills/` (Cursor)
- `~/.claude/skills/` (Claude Code)

## Skill sources

| Key | Repository |
|-----|------------|
| `karpathy` | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) |
| `mattpocock` | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `9arm` | [thananon/9arm-skills](https://github.com/thananon/9arm-skills) |

## Common commands

```bash
# Defaults: all repos, symlink, cursor + claude
./scripts/install-skills.sh

# Matt Pocock via skills.sh + symlink the rest
./scripts/install-skills.sh --method all

# Karpathy Cursor rule in current project
./scripts/install-skills.sh --repos karpathy --target cursor --project .

# Subset + update cache
./scripts/install-skills.sh --repos 9arm,mattpocock --update

./scripts/install-skills.sh --help
```

**After install (Matt Pocock):** run `/setup-matt-pocock-skills` once per project, then skills like `/grill-me`, `/tdd`, `/diagnose`.

See **[EXAMPLES.md](EXAMPLES.md)** for Thai/English prompt examples and troubleshooting.

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--target` | `both` | `cursor`, `claude`, or `both` |
| `--method` | `symlink` | `symlink`, `npx`, or `all` (npx applies to mattpocock only) |
| `--repos` | all three | Comma-separated: `karpathy,mattpocock,9arm` |
| `--project DIR` | — | Copy Karpathy `.mdc` rule into `DIR/.cursor/rules/` |
| `--dry-run` | off | Show actions only |
| `--update` | off | `git pull --ff-only` in cache, then re-link |

## Notes

- **Symlink installs** point into the cache; use `--update` to refresh upstream.
- **Name collisions:** if `~/.cursor/skills/foo` already exists as a real directory (not a symlink), the script skips it and warns instead of overwriting.
- **Karpathy in Claude Code** can also use the [plugin marketplace](https://github.com/multica-ai/andrej-karpathy-skills#install) from the upstream README.

## Layout

```
scripts/
  install-skills.sh      # macOS / Linux
  install-skills.cmd     # Windows (CMD)
  lib/skills-common.sh   # shared logic for .sh
EXAMPLES.md              # usage examples
```

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/skills-common.sh
source "$SCRIPT_DIR/lib/skills-common.sh"

TARGET="both"
METHOD="symlink"
REPOS="karpathy,mattpocock,9arm"
PROJECT_DIR=""
DRY_RUN=false
UPDATE=false

usage() {
  cat <<'EOF'
Usage: install-skills.sh [OPTIONS]

Install agent skills from three GitHub repos into Cursor and/or Claude Code.

Options:
  --target TARGET     cursor | claude | both (default: both)
  --method METHOD     symlink | npx | all (default: symlink; npx/all apply to mattpocock only)
  --repos LIST        Comma-separated: karpathy,mattpocock,9arm (default: all three)
  --project DIR       Copy Karpathy .cursor/rules into DIR (Cursor project rule)
  --dry-run           Print actions without changing the system
  --update            git pull --ff-only in the skills cache
  -h, --help          Show this help

Cache: ${XDG_DATA_HOME:-$HOME/.local/share}/init-ai/skills-cache/

Examples:
  ./scripts/install-skills.sh
  ./scripts/install-skills.sh --method all
  ./scripts/install-skills.sh --target cursor --project .
  ./scripts/install-skills.sh --repos karpathy,9arm --update

See EXAMPLES.md for usage after install.

Windows: scripts\\install-skills.cmd
EOF
}

parse_repos() {
  local list="$1"
  IFS=',' read -ra SELECTED_REPOS <<< "$list"
  for r in "${SELECTED_REPOS[@]}"; do
    r="${r// /}"
    case "$r" in
      karpathy|mattpocock|9arm) ;;
      *)
        log_err "unknown repo: $r (expected karpathy, mattpocock, or 9arm)"
        exit 1
        ;;
    esac
  done
}

repo_selected() {
  local key="$1"
  local r
  for r in "${SELECTED_REPOS[@]}"; do
    r="${r// /}"
    if [[ "$r" == "$key" ]]; then
      return 0
    fi
  done
  return 1
}

install_to_dest() {
  local dest="$1"
  local dest_label="$2"

  log_info "Installing to $dest_label ($dest)"

  if repo_selected karpathy; then
    local krepo
    krepo="$(repo_path karpathy)"
    install_karpathy_skill "$krepo" "$dest" "$DRY_RUN"
  fi

  if repo_selected mattpocock && [[ "$METHOD" == "symlink" || "$METHOD" == "all" ]]; then
    local mrepo
    mrepo="$(repo_path mattpocock)"
    link_skills_from_tree "$mrepo" "$dest" "$DRY_RUN" "mattpocock"
  fi

  if repo_selected 9arm; then
    local arepo
    arepo="$(repo_path 9arm)"
    link_skills_from_tree "$arepo" "$dest" "$DRY_RUN" "9arm"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --method)
      METHOD="$2"
      shift 2
      ;;
    --repos)
      REPOS="$2"
      shift 2
      ;;
    --project)
      PROJECT_DIR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --update)
      UPDATE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_err "unknown option: $1"
      usage >&2
      exit 1
      ;;
  esac
done

case "$TARGET" in
  cursor|claude|both) ;;
  *)
    log_err "invalid --target: $TARGET (use cursor, claude, or both)"
    exit 1
    ;;
esac

case "$METHOD" in
  symlink|npx|all) ;;
  *)
    log_err "invalid --method: $METHOD (use symlink, npx, or all)"
    exit 1
    ;;
esac

parse_repos "$REPOS"

if [[ -n "$PROJECT_DIR" ]] && ! repo_selected karpathy; then
  log_warn "--project is only used with karpathy; add karpathy to --repos to copy the rule"
fi

if [[ -n "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
fi

# Ensure cache for selected repos
for key in karpathy mattpocock 9arm; do
  if repo_selected "$key"; then
    ensure_cache_repo "$key" "$UPDATE" "$DRY_RUN"
  fi
done

# Karpathy project rule (optional)
if [[ -n "$PROJECT_DIR" ]] && repo_selected karpathy; then
  install_karpathy_project_rule "$(repo_path karpathy)" "$PROJECT_DIR" "$DRY_RUN"
fi

# mattpocock via npx (optional)
if repo_selected mattpocock && [[ "$METHOD" == "npx" || "$METHOD" == "all" ]]; then
  install_mattpocock_npx "$DRY_RUN" || true
fi

# Symlink installs per target
case "$TARGET" in
  cursor)
    install_to_dest "$(cursor_skills_dest)" "Cursor"
    ;;
  claude)
    install_to_dest "$(claude_skills_dest)" "Claude Code"
    ;;
  both)
    install_to_dest "$(cursor_skills_dest)" "Cursor"
    install_to_dest "$(claude_skills_dest)" "Claude Code"
    ;;
esac

echo ""
log_info "Done."
if repo_selected mattpocock; then
  echo "  Matt Pocock: run /setup-matt-pocock-skills once per project (after npx or symlink install)."
fi
if repo_selected karpathy && [[ -z "$PROJECT_DIR" ]]; then
  echo "  Karpathy: add --project DIR to copy the always-on Cursor rule into a repo."
fi
echo "  See EXAMPLES.md for prompt examples."

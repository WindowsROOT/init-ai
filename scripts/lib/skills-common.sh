#!/usr/bin/env bash
# Shared helpers for install-skills.sh

set -euo pipefail

CACHE_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/init-ai/skills-cache"

log_info() {
  echo "==> $*"
}

log_warn() {
  echo "warning: $*" >&2
}

log_err() {
  echo "error: $*" >&2
}

repo_url() {
  case "$1" in
    karpathy) echo "https://github.com/multica-ai/andrej-karpathy-skills.git" ;;
    mattpocock) echo "https://github.com/mattpocock/skills.git" ;;
    9arm) echo "https://github.com/thananon/9arm-skills.git" ;;
    *)
      log_err "unknown repo key: $1"
      exit 1
      ;;
  esac
}

repo_dirname() {
  case "$1" in
    karpathy) echo "andrej-karpathy-skills" ;;
    mattpocock) echo "mattpocock-skills" ;;
    9arm) echo "9arm-skills" ;;
    *)
      log_err "unknown repo key: $1"
      exit 1
      ;;
  esac
}

repo_path() {
  echo "${CACHE_ROOT}/$(repo_dirname "$1")"
}

# Portable realpath (macOS readlink lacks -f).
realpath_compat() {
  local path="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$path"
  elif command -v greadlink >/dev/null 2>&1; then
    greadlink -f "$path"
  elif readlink -f "$path" >/dev/null 2>&1; then
    readlink -f "$path"
  else
    echo "$path"
  fi
}

# Bail if DEST is a symlink that resolves into repo (avoids polluting the cache tree).
guard_dest_not_symlink_into_repo() {
  local dest="$1"
  local repo="$2"

  if [[ ! -L "$dest" ]]; then
    return 0
  fi

  local resolved
  resolved="$(realpath_compat "$dest")"

  case "$resolved" in
    "$repo"|"$repo"/*)
      log_err "$dest is a symlink into the skills cache ($resolved)."
      log_err "Remove it (rm \"$dest\") and re-run; the script will recreate it as a real directory."
      exit 1
      ;;
  esac
}

ensure_cache_repo() {
  local key="$1"
  local update="${2:-false}"
  local dry_run="${3:-false}"

  local url dir
  url="$(repo_url "$key")"
  dir="$(repo_path "$key")"

  if [[ -d "$dir/.git" ]]; then
    if [[ "$update" == "true" ]]; then
      if [[ "$dry_run" == "true" ]]; then
        log_info "[dry-run] would git pull --ff-only in $dir"
      else
        log_info "Updating $key ($dir)"
        git -C "$dir" pull --ff-only
      fi
    else
      log_info "Using cached $key ($dir)"
    fi
    return 0
  fi

  if [[ "$dry_run" == "true" ]]; then
    log_info "[dry-run] would git clone --depth 1 $url $dir"
    return 0
  fi

  mkdir -p "$CACHE_ROOT"
  log_info "Cloning $key from $url"
  git clone --depth 1 "$url" "$dir"
}

mkdir_dest() {
  local dest="$1"
  local dry_run="$2"

  if [[ "$dry_run" == "true" ]]; then
    log_info "[dry-run] would mkdir -p $dest"
  else
    mkdir -p "$dest"
  fi
}

# Symlink every shippable skill under repo/skills into dest.
link_skills_from_tree() {
  local repo="$1"
  local dest="$2"
  local dry_run="${3:-false}"
  local label="${4:-skills}"

  if [[ ! -d "$repo/skills" ]]; then
    log_warn "$label: no skills/ directory in $repo — skipping"
    return 0
  fi

  guard_dest_not_symlink_into_repo "$dest" "$repo"
  mkdir_dest "$dest" "$dry_run"

  local linked=0
  local skipped=0

  while IFS= read -r -d '' skill_md; do
    local src name target existing_target

    src="$(dirname "$skill_md")"
    name="$(basename "$src")"
    target="$dest/$name"

    if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
      log_warn "$label: $target exists and is not a symlink — skipping $name"
      skipped=$((skipped + 1))
      continue
    fi

    if [[ -L "$target" ]]; then
      existing_target="$(realpath_compat "$target")"
      if [[ "$existing_target" == "$(realpath_compat "$src")" ]]; then
        echo "  ok $name (already linked)"
        continue
      fi
      log_warn "$label: $name already linked elsewhere ($target -> $existing_target) — skipping"
      skipped=$((skipped + 1))
      continue
    fi

    if [[ "$dry_run" == "true" ]]; then
      echo "  [dry-run] would link $name -> $src"
    else
      ln -sfn "$src" "$target"
      echo "  linked $name -> $src"
    fi
    linked=$((linked + 1))
  done < <(
    find "$repo/skills" -name SKILL.md \
      -not -path '*/node_modules/*' \
      -not -path '*/deprecated/*' \
      -not -path '*/in-progress/*' \
      -not -path '*/personal/*' \
      -print0
  )

  log_info "$label: linked $linked skill(s), skipped $skipped"
}

install_karpathy_skill() {
  local repo="$1"
  local dest="$2"
  local dry_run="${3:-false}"

  local src="$repo/skills/karpathy-guidelines"
  local target="$dest/karpathy-guidelines"

  if [[ ! -f "$src/SKILL.md" ]]; then
    log_warn "karpathy: $src/SKILL.md not found — skipping skill link"
    return 0
  fi

  guard_dest_not_symlink_into_repo "$dest" "$repo"
  mkdir_dest "$dest" "$dry_run"

  if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
    log_warn "karpathy: $target exists and is not a symlink — skipping"
    return 0
  fi

  if [[ -L "$target" ]]; then
    local existing_target src_resolved
    existing_target="$(realpath_compat "$target")"
    src_resolved="$(realpath_compat "$src")"
    if [[ "$existing_target" == "$src_resolved" ]]; then
      echo "  ok karpathy-guidelines (already linked)"
      return 0
    fi
    log_warn "karpathy: karpathy-guidelines already linked elsewhere — skipping"
    return 0
  fi

  if [[ "$dry_run" == "true" ]]; then
    log_info "[dry-run] would link karpathy-guidelines -> $src"
  else
    ln -sfn "$src" "$target"
    echo "  linked karpathy-guidelines -> $src"
  fi
}

install_karpathy_project_rule() {
  local repo="$1"
  local project_dir="$2"
  local dry_run="${3:-false}"

  local rule_src="$repo/.cursor/rules/karpathy-guidelines.mdc"
  local rules_dest="$project_dir/.cursor/rules"
  local rule_dest="$rules_dest/karpathy-guidelines.mdc"

  if [[ ! -f "$rule_src" ]]; then
    log_warn "karpathy: project rule not found at $rule_src — skipping"
    return 0
  fi

  if [[ "$dry_run" == "true" ]]; then
    log_info "[dry-run] would copy $rule_src -> $rule_dest"
    return 0
  fi

  mkdir -p "$rules_dest"
  cp "$rule_src" "$rule_dest"
  echo "  copied Karpathy rule -> $rule_dest"
}

install_mattpocock_npx() {
  local dry_run="${1:-false}"

  if [[ "$dry_run" == "true" ]]; then
    log_info "[dry-run] would run: npx skills@latest add mattpocock/skills -g -y"
    return 0
  fi

  if ! command -v npx >/dev/null 2>&1; then
    log_err "npx not found — install Node.js or use --method symlink"
    return 1
  fi

  log_info "Installing mattpocock/skills via npx skills (global, non-interactive)"
  if npx skills@latest add mattpocock/skills -g -y; then
    log_info "mattpocock: npx skills add succeeded"
    echo ""
    echo "Next: open your agent in a project repo and run /setup-matt-pocock-skills"
    return 0
  fi

  log_warn "mattpocock: npx skills add failed — try --method symlink or run interactively:"
  echo "  npx skills@latest add mattpocock/skills"
  return 1
}

cursor_skills_dest() {
  echo "$HOME/.cursor/skills"
}

claude_skills_dest() {
  echo "$HOME/.claude/skills"
}

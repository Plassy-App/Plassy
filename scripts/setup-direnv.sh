#!/usr/bin/env bash
# Trust all committed .envrc files (source_up stubs + optional root secrets file).
# Invoked from `bun install` (prepare) and git post-checkout — no manual `direnv allow` per folder.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if ! command -v direnv >/dev/null 2>&1; then
  cat >&2 <<'EOF'
[direnv] Not installed — NODE_AUTH_TOKEN will not load automatically in subfolders.
  macOS: brew install direnv
  Then add to ~/.zshrc: eval "$(direnv hook zsh)"
  Re-run: bun run setup:direnv
EOF
  exit 0
fi

if [[ ! -f .envrc.local ]] && [[ -f .envrc.local.example ]]; then
  cp .envrc.local.example .envrc.local
  echo "[direnv] Created .envrc.local from .envrc.local.example — set your GitHub PAT (read:packages), then re-run: bun run setup:direnv"
fi

if [[ ! -f .envrc ]]; then
  echo "[direnv] Missing committed .envrc stub at repo root; pull latest main." >&2
  exit 0
fi

allowed=0
while IFS= read -r -d '' envrc; do
  if direnv allow "$envrc" >/dev/null 2>&1; then
    allowed=$((allowed + 1))
  fi
done < <(find . \( -name node_modules -o -name .git \) -prune -o -name .envrc -print0)

echo "[direnv] Allowed ${allowed} .envrc file(s) under ${root}."

if grep -q 'REPLACE_WITH_github_pat' .envrc.local 2>/dev/null; then
  echo "[direnv] Reminder: edit .envrc.local at repo root with your GitHub PAT (read:packages)." >&2
fi

if ! grep -q 'direnv hook' "${HOME}/.zshrc" "${HOME}/.bashrc" 2>/dev/null; then
  cat >&2 <<'EOF'
[direnv] Add the shell hook so new terminals load NODE_AUTH_TOKEN on cd:
  eval "$(direnv hook zsh)"   # add once to ~/.zshrc
EOF
fi

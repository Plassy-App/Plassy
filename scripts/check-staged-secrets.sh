#!/usr/bin/env bash
# Refuse commits that stage GitHub tokens (classic PAT, fine-grained, OAuth).
set -euo pipefail

token_pattern='ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]+|gho_[A-Za-z0-9]+'

while IFS= read -r -d '' file; do
  case "$file" in
    *.example | */.envrc.local.example) continue ;;
  esac
  if git show ":$file" 2>/dev/null | grep -qE "$token_pattern"; then
    echo "[secrets] Refusing to commit: possible GitHub token in $file" >&2
    echo "[secrets] Revoke the token at https://github.com/settings/tokens and use .envrc.local (gitignored)." >&2
    exit 1
  fi
done < <(git diff --cached --name-only --diff-filter=ACM -z)

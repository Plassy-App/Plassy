#!/usr/bin/env bash
# Block commits that stage secrets. Uses gitleaks when installed (same rules as CI);
# falls back to high-confidence regex patterns otherwise.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if command -v gitleaks >/dev/null 2>&1; then
  gitleaks protect --staged --source . --verbose --redact
  exit $?
fi

echo "[secrets] gitleaks not installed — using basic pattern check." >&2
echo "[secrets] For full coverage (same rules as CI): brew install gitleaks" >&2

# Fallback: high-confidence patterns only (no OpenAI sk- etc. — too many false positives).
secret_pattern='ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]+|gho_[A-Za-z0-9]+|sqp_[a-f0-9]{40}|AKIA[0-9A-Z]{16}|sk_(live|test)_[A-Za-z0-9]{16,}|rk_(live|test)_[A-Za-z0-9]{16,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'

paths=()
while IFS= read -r -d '' file; do
  case "$file" in
    *.example | */.envrc.local.example) continue ;;
  esac
  paths+=("$file")
done < <(git diff --cached --name-only --diff-filter=ACM -z)

if ((${#paths[@]} == 0)); then
  exit 0
fi

if matched_files=$(git grep --cached -I -l -E "$secret_pattern" -- "${paths[@]}" 2>/dev/null); then
  echo "[secrets] Refusing to commit: possible secret in:" >&2
  echo "$matched_files" | sed 's/^/  /' >&2
  echo "[secrets] Move credentials to a gitignored file (.envrc.local, .env.local…)." >&2
  echo "[secrets] Revoke any exposed token and install gitleaks for broader detection." >&2
  exit 1
fi

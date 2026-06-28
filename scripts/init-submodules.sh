#!/usr/bin/env bash
# Initialize private git submodules in environments without SSH (e.g. Cursor Cloud Agents).
# Rewrites SSH URLs from .gitmodules to HTTPS with GH_TOKEN or SUBMODULES_PAT.
set -euo pipefail

TOKEN="${GH_TOKEN:-${SUBMODULES_PAT:-}}"
if [[ -z "$TOKEN" ]]; then
  echo "Missing GH_TOKEN or SUBMODULES_PAT runtime secret" >&2
  exit 1
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if [[ ! -f .gitmodules ]]; then
  echo "[submodules] No .gitmodules found; skipping." >&2
  exit 0
fi

args=()
while IFS= read -r line; do
  key="${line%% *}"
  ssh_url="${line#* }"
  name="${key#submodule.}"
  name="${name%.url}"
  repo="${ssh_url#git@github.com:}"
  args+=(-c "submodule.${name}.url=https://x-access-token:${TOKEN}@github.com/${repo}")
done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.url')

git "${args[@]}" submodule update --init --recursive

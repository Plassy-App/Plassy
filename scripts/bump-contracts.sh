#!/usr/bin/env bash
# Bump @plassy-app/api-contracts in all consumers after publishing the version.
# Usage: ./scripts/bump-contracts.sh 2.1.0
set -euo pipefail

VERSION="${1:?Usage: ./scripts/bump-contracts.sh X.Y.Z}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for pkg in plassy-backend plassy-scraper plassy-app; do
  echo "→ $pkg: @plassy-app/api-contracts@${VERSION}"
  (cd "$ROOT/$pkg" && bun add --exact "@plassy-app/api-contracts@${VERSION}")
done

echo ""
echo "Done. Commit package.json and bun.lock in each consumer."
echo "Publish order: contracts tag → wait for GitHub Packages → then deploy backend → scraper → app."

#!/usr/bin/env bash
# Umbrella workspace: warn when consumers pin an older @plassy-app/api-contracts
# than plassy-contracts/package.json.
# Semver bump fail runs on Plassy-Contracts CI (scripts/check-version-bump.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTRACTS_PKG="$ROOT/plassy-contracts/package.json"
CONSUMERS=(plassy-backend plassy-scraper plassy-app)

read_version() {
  node -p "require('${1}').version"
}

read_consumer_version() {
  node -p "
    const v = require('${1}').dependencies?.['@plassy-app/api-contracts'];
    if (!v) process.exit(2);
    process.stdout.write(String(v).replace(/^[\^~]/, ''));
  "
}

version_lt() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ] && [ "$1" != "$2" ]
}

if [ ! -f "$CONTRACTS_PKG" ]; then
  echo "::warning::plassy-contracts submodule not found — skip consumer version check"
  exit 0
fi

CURRENT_VERSION="$(read_version "$CONTRACTS_PKG")"
WARNINGS=0

for consumer in "${CONSUMERS[@]}"; do
  PKG_JSON="$ROOT/$consumer/package.json"
  if [ ! -f "$PKG_JSON" ]; then
    continue
  fi

  if ! CONSUMER_VERSION="$(read_consumer_version "$PKG_JSON" 2>/dev/null)"; then
    echo "::warning::$consumer has no @plassy-app/api-contracts dependency"
    WARNINGS=$((WARNINGS + 1))
    continue
  fi

  if version_lt "$CONSUMER_VERSION" "$CURRENT_VERSION"; then
    echo "::warning::$consumer pins @plassy-app/api-contracts@${CONSUMER_VERSION} but plassy-contracts is ${CURRENT_VERSION}. Run: ./scripts/bump-contracts.sh ${CURRENT_VERSION}"
    WARNINGS=$((WARNINGS + 1))
  fi
done

echo "Contracts workspace check OK (contracts=${CURRENT_VERSION}, consumer warnings=${WARNINGS})"

#!/usr/bin/env bash
# Decide whether the next preview iOS deploy should be OTA or a new cloud build.
# Mirrors plassy-app/.eas/workflows/preview-deploy.yml (fingerprint + get-build).
#
# Usage:
#   ./scripts/preview-deploy-check.sh
#   ./scripts/preview-deploy-check.sh --pull-env
#   ./scripts/preview-deploy-check.sh --update --message "fix: my change"
#
# Exit codes:
#   0 — compatible preview build exists (OTA)
#   1 — no compatible build (new iOS build + TestFlight required)
#   2 — error (missing tools, not logged in, etc.)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/plassy-app"
PROFILE="preview"
PLATFORM="ios"
CHANNEL="preview"
DISTRIBUTION="store"

PULL_ENV=false
RUN_UPDATE=false
JSON_OUTPUT=false
MESSAGE=""

usage() {
  cat <<'EOF'
Usage: ./scripts/preview-deploy-check.sh [options]

Options:
  --pull-env           Pull EAS preview env vars into plassy-app/.env before fingerprinting
  --update             Publish an OTA update when a compatible build exists
  --message <text>     OTA message (required with --update)
  --json               Machine-readable JSON output
  -h, --help           Show this help

Examples:
  ./scripts/preview-deploy-check.sh
  ./scripts/preview-deploy-check.sh --pull-env
  ./scripts/preview-deploy-check.sh --update --message "fix: login screen"

When the result is OTA, you can skip the EAS workflow queue after merging:
  git commit -m "fix: ... [eas skip]"
  ./scripts/preview-deploy-check.sh --update --message "fix: ..."
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pull-env)
      PULL_ENV=true
      shift
      ;;
    --update)
      RUN_UPDATE=true
      shift
      ;;
    --message)
      MESSAGE="${2:?--message requires a value}"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ ! -d "$APP_DIR" ]; then
  echo "error: plassy-app not found at $APP_DIR" >&2
  exit 2
fi

if ! command -v eas >/dev/null 2>&1; then
  echo "error: eas CLI not found (npm install -g eas-cli)" >&2
  exit 2
fi

if ! command -v node >/dev/null 2>&1; then
  echo "error: node is required" >&2
  exit 2
fi

if [ "$RUN_UPDATE" = true ] && [ -z "$MESSAGE" ]; then
  echo "error: --update requires --message" >&2
  exit 2
fi

cd "$APP_DIR"

if [ "$PULL_ENV" = true ]; then
  eas env:pull preview --non-interactive
fi

FINGERPRINT_JSON="$(
  npx --yes @expo/fingerprint fingerprint:generate --platform "$PLATFORM"
)"
FINGERPRINT_HASH="$(
  node -e "const data = JSON.parse(process.argv[1]); if (!data.hash) process.exit(1); process.stdout.write(data.hash);" "$FINGERPRINT_JSON"
)"

set +e
BUILDS_JSON="$(
  eas build:list \
    -p "$PLATFORM" \
    -e "$PROFILE" \
    --distribution "$DISTRIBUTION" \
    --status finished \
    --fingerprint-hash "$FINGERPRINT_HASH" \
    --limit 1 \
    --json \
    --non-interactive 2>&1
)"
BUILDS_EXIT=$?
set -e

if [ "$BUILDS_EXIT" -ne 0 ]; then
  echo "error: eas build:list failed (run eas login?)" >&2
  echo "$BUILDS_JSON" >&2
  exit 2
fi

read -r BUILD_COUNT BUILD_ID LATEST_BUILD_FP <<EOF
$(node -e "
  const raw = process.argv[1];
  let data;
  try {
    data = JSON.parse(raw);
  } catch {
    console.log('0');
    process.exit(0);
  }
  const builds = Array.isArray(data) ? data : (data.builds ?? data.data ?? []);
  const build = builds[0];
  if (!build) {
    console.log('0');
    process.exit(0);
  }
  const buildId = build.id ?? build.buildId ?? '';
  const buildFp = build.fingerprintHash ?? build.fingerprint?.hash ?? '';
  console.log([builds.length, buildId, buildFp].join(' '));
" "$BUILDS_JSON")
EOF

set +e
LATEST_PREVIEW_JSON="$(
  eas build:list \
    -p "$PLATFORM" \
    -e "$PROFILE" \
    --distribution "$DISTRIBUTION" \
    --status finished \
    --limit 1 \
    --json \
    --non-interactive 2>&1
)"
LATEST_EXIT=$?
set -e

if [ "$LATEST_EXIT" -ne 0 ]; then
  echo "error: eas build:list failed while fetching latest preview build" >&2
  echo "$LATEST_PREVIEW_JSON" >&2
  exit 2
fi

read -r LATEST_BUILD_ID LATEST_BUILD_FP <<EOF
$(node -e "
  const raw = process.argv[1];
  let data;
  try {
    data = JSON.parse(raw);
  } catch {
    console.log(' ');
    process.exit(0);
  }
  const builds = Array.isArray(data) ? data : (data.builds ?? data.data ?? []);
  const build = builds[0];
  if (!build) {
    console.log(' ');
    process.exit(0);
  }
  const buildId = build.id ?? build.buildId ?? '';
  const buildFp = build.fingerprintHash ?? build.fingerprint?.hash ?? '';
  console.log([buildId, buildFp].join(' '));
" "$LATEST_PREVIEW_JSON")
EOF

if [ "$BUILD_COUNT" -gt 0 ]; then
  ACTION="ota"
  EXIT_CODE=0
else
  ACTION="build"
  EXIT_CODE=1
fi

if [ "$JSON_OUTPUT" = true ]; then
  node -e "
    const payload = {
      action: process.argv[1],
      fingerprintHash: process.argv[2],
      compatibleBuildId: process.argv[3] || null,
      latestPreviewBuildId: process.argv[4] || null,
      latestPreviewFingerprintHash: process.argv[5] || null,
      profile: process.argv[6],
      platform: process.argv[7],
      channel: process.argv[8],
    };
    console.log(JSON.stringify(payload, null, 2));
  " "$ACTION" "$FINGERPRINT_HASH" "$BUILD_ID" "$LATEST_BUILD_ID" "$LATEST_BUILD_FP" "$PROFILE" "$PLATFORM" "$CHANNEL"
else
  echo "Preview deploy check (iOS / profile: $PROFILE)"
  echo "Fingerprint: $FINGERPRINT_HASH"
  echo ""

  if [ "$ACTION" = "ota" ]; then
    echo "Result: OTA update"
    echo "Compatible build: $BUILD_ID"
    echo ""
    echo "You can publish locally without waiting for the EAS workflow queue:"
    echo "  cd plassy-app"
    echo "  eas update --channel $CHANNEL --platform $PLATFORM --message \"<message>\" --non-interactive"
    echo ""
    echo "To skip the workflow on merge, add [eas skip] to the commit message."
  else
    echo "Result: new iOS build required"
    echo "No finished preview build matches this fingerprint."
    if [ -n "$LATEST_BUILD_ID" ]; then
      echo "Latest preview build: $LATEST_BUILD_ID"
      if [ -n "$LATEST_BUILD_FP" ] && [ "$LATEST_BUILD_FP" != "$FINGERPRINT_HASH" ]; then
        echo "Latest build fingerprint: $LATEST_BUILD_FP"
        echo "Native layer changed since the last preview build."
      fi
    else
      echo "No finished preview iOS build found on EAS."
    fi
    echo ""
    echo "Let preview-deploy.yml run after merge, or trigger manually:"
    echo "  cd plassy-app"
    echo "  eas build -p $PLATFORM -e $PROFILE"
  fi
fi

if [ "$RUN_UPDATE" = true ]; then
  if [ "$ACTION" != "ota" ]; then
    echo "error: --update refused because no compatible preview build exists" >&2
    exit 1
  fi

  eas update \
    --channel "$CHANNEL" \
    --platform "$PLATFORM" \
    --message "$MESSAGE" \
    --non-interactive
fi

exit "$EXIT_CODE"

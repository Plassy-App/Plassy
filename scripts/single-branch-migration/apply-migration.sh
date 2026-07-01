#!/usr/bin/env bash
# Apply single-branch (main-only) CI/CD to Plassy submodule repos.
# Run locally with SUBMODULES_PAT set, or via .github/workflows/single-branch-migration.yml
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMPLATES="$ROOT/scripts/single-branch-migration/templates"
WORK_DIR="${WORK_DIR:-/tmp/plassy-single-branch-migration}"
MERGE_PREVIEW="${MERGE_PREVIEW:-true}"
DRY_RUN="${DRY_RUN:-false}"
PAT="${SUBMODULES_PAT:?SUBMODULES_PAT is required}"

mkdir -p "$WORK_DIR"

clone_repo() {
  local name="$1"
  local dir="$WORK_DIR/$name"
  rm -rf "$dir"
  git clone "https://x-access-token:${PAT}@github.com/Plassy-App/${name}.git" "$dir"
  echo "$dir"
}

merge_preview_into_main() {
  local dir="$1"
  (
    cd "$dir"
    git fetch origin main preview 2>/dev/null || git fetch origin main
    git checkout main
    git pull origin main
    if [ "$MERGE_PREVIEW" = "true" ] && git ls-remote --heads origin preview | grep -q preview; then
      if git merge-base --is-ancestor origin/preview HEAD 2>/dev/null; then
        echo "  preview already merged into main"
      else
        git merge origin/preview -m "chore: merge preview into main (single-branch migration)"
      fi
    fi
  )
}

copy_templates() {
  local repo_key="$1"
  local dir="$2"
  local src="$TEMPLATES/$repo_key"
  if [ -d "$src" ]; then
    cp -R "$src/." "$dir/"
  fi
}

patch_test_branches() {
  local dir="$1"
  local test_file="$dir/.github/workflows/test.yml"
  if [ -f "$test_file" ]; then
    sed -i \
      -e 's/branches: \[main, dev\]/branches: [main]/' \
      -e 's/branches: \[main, preview\]/branches: [main]/' \
      -e 's/branches: \[preview, main\]/branches: [main]/' \
      -e 's/branches: \[preview\]/branches: [main]/' \
      "$test_file"
  fi
}

commit_and_push() {
  local dir="$1"
  local message="$2"
  (
    cd "$dir"
    if git diff --quiet && git diff --cached --quiet; then
      echo "  no changes to commit"
      return 0
    fi
    git config user.name "github-actions[bot]"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git add -A
    git status --short
    git commit -m "$message"
    if [ "$DRY_RUN" = "true" ]; then
      echo "  dry run — skipping push"
    else
      git push origin main
    fi
  )
}

migrate_repo() {
  local gh_name="$1"
  local template_key="$2"
  local commit_msg="$3"

  echo ""
  echo "=== $gh_name ==="
  local dir
  dir="$(clone_repo "$gh_name")"
  merge_preview_into_main "$dir"
  copy_templates "$template_key" "$dir"
  patch_test_branches "$dir"
  commit_and_push "$dir" "$commit_msg"
}

echo "Single-branch migration (MERGE_PREVIEW=$MERGE_PREVIEW, DRY_RUN=$DRY_RUN)"

migrate_repo "Plassy-Backend" "plassy-backend" \
  "ci: deploy preview on main push, production on release tag"

migrate_repo "Plassy-Scraper" "plassy-scraper" \
  "ci: deploy preview on main push, production on release tag"

migrate_repo "Plassy-Contracts" "plassy-contracts" \
  "ci: auto-tag preview packages on main push"

migrate_repo "Plassy-App" "plassy-app" \
  "ci: single-branch main — preview on push, production on release tag"

echo ""
echo "Migration complete."

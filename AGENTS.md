# Plassy Cloud Agent — Preview Workflow

This document describes how Cursor Cloud Agents should work across the Plassy ecosystem to deliver changes testable on a physical iOS device, **without touching production** and **without Metro / ngrok**.

## Goal

When a preview task is requested:

1. Implement changes on dedicated branches from `main`.
2. Open **draft PRs** targeting `main`.
3. After human merge → automatic **preview** deployment (Railway + EAS via GitHub Actions).
4. The tester validates on a physical device (TestFlight or OTA).
5. When ready for production → create a **GitHub Release** / tag `vX.Y.Z` → production deploy.

## Single-branch architecture

One long-lived integration branch: **`main`**. Preview and production are **environments**, not branches.

| Layer            | Repo               | PR target | Preview trigger     | Production trigger        |
| ---------------- | ------------------ | --------- | ------------------- | ------------------------- |
| **Mobile app**   | `plassy-app`       | `main`    | push to `main`      | tag `vX.Y.Z` (no preview) |
| **Backend API**  | `plassy-backend`   | `main`    | push to `main`      | tag `vX.Y.Z`              |
| **Scraper**      | `plassy-scraper`   | `main`    | push to `main`      | tag `vX.Y.Z`              |
| **Contracts**    | `plassy-contracts` | `main`    | push to `main`      | tag `vX.Y.Z` (stable)     |
| **Web frontend** | `plassy-frontend`  | `main`    | —                   | —                         |
| **Umbrella**     | `Plassy` (root)    | `dev`     | CI only             | —                         |

### Environments

| Env            | App backend URL                                                         | Deploy mechanism                          | Data                                       |
| -------------- | ----------------------------------------------------------------------- | ----------------------------------------- | ------------------------------------------ |
| **Preview**    | `EXPO_PUBLIC_BACKEND_URL=https://plassy-backend-preview.up.railway.app` | GitHub Actions on push to `main`          | Isolated Neon preview DB, Redis/S3 preview |
| **Production** | `https://api.plassy.fr`                                                 | GitHub Actions on release tag `vX.Y.Z`    | Production                                 |

**Never** point the `preview` profile at `api.plassy.fr`. **Never** use ngrok in an EAS preview build (blocked in code).

Railway **auto-deploy is disabled** on both environments. Deployments are triggered exclusively by GitHub Actions (`railway up` with environment-scoped project tokens).

### Expo / EAS

| Item                  | Value                                                                            |
| --------------------- | -------------------------------------------------------------------------------- |
| Expo org              | `@plassy/plassy`                                                                 |
| Project               | `@plassy/plassy` (`extra.eas.projectId`: `8be05f22-a61c-4959-a5d6-a526667fc22a`) |
| `app.json` → `owner`  | `"plassy"` (must match the Expo org)                                             |
| Connected GitHub repo | `Plassy-App/Plassy-App`                                                          |
| Preview               | GH Action `.github/workflows/preview-deploy.yml` on push to `main`               |
| Production            | GH Action `.github/workflows/deploy-production.yml` on tag `v*`                  |
| Manual fallback       | `.eas/workflows/preview-deploy.yml`, `.eas/workflows/production-deploy.yml`      |
| TestFlight submit     | `submit.preview.ios.ascAppId`: `6762057582`                                      |

## Standard flow (one feature request)

```mermaid
flowchart TD
    A[Feature request] --> B[Branch cursor/... from main]
    B --> C{Contracts changed?}
    C -->|yes| D[PR contracts → main with X.Y.Z-preview.N version]
    D --> E[Merge → auto-tag → npm publish ~2-3 min]
    E --> F[bump-contracts.sh on consumers]
    C -->|no| F
    F --> G[Draft PRs → main app / backend / scraper]
    G --> H[Human review and merge]
    H --> I[GH Actions: Railway preview backend + scraper]
    H --> J[GH Actions: app preview OTA or TestFlight]
    J --> K{Native change?}
    K -->|no| L[OTA on preview channel]
    K -->|yes| M[iOS build + TestFlight submit]
    L --> N[Tester reopens the app]
    M --> O[Tester installs from TestFlight]
    O --> P{Ready for prod?}
    P -->|yes| Q[GitHub Release vX.Y.Z]
    Q --> R[GH Actions: Railway prod + app prod + contracts stable]
```

### Agent steps

1. **Initialize submodules** if needed: `git submodule update --init --recursive`.
2. **Create a branch** per touched repo: `cursor/<description>-7c6d` (from `main`).
3. **Implement** changes following each repo's conventions.
4. **Commit and push** on each touched branch (`git push -u origin <branch>`).
5. **Open draft PRs** (mandatory — never leave a task with only a pushed branch):
   - `plassy-app` → base `main`
   - `plassy-backend` → base `main`
   - `plassy-scraper` → base `main`
   - `plassy-contracts` → base `main`
   - umbrella `Plassy` → base `dev` (only when root files change)
6. **Describe in each PR**: scope, merge order, expected testing actions.
7. **Wait for human merge** — do not merge unless explicitly instructed.

After merge to `main` (app):

- The GitHub Actions preview workflow triggers **automatically**.
- **JS/TS changes only** → OTA (~2–3 min): the tester **reopens the app**; no new TestFlight build required.
- **Native changes** (Expo plugins, permissions, Mapbox, share extension, `appVersion` bump, etc.) → build + TestFlight submit (~15–25 min): the tester **installs the new build**.

## Contracts (`plassy-contracts`)

The `@plassy-app/api-contracts` package is published to **GitHub Packages**, not deployed on Railway.

### When contracts change

**Mandatory order**:

1. Modify `plassy-contracts` on a branch from `main`.
2. Bump the version as a **prerelease** in `package.json` (e.g. `3.5.0-preview.1`).
3. Update `CHANGELOG.md`.
4. Open a draft PR → `main`.
5. **Merge to main** → `tag-preview.yml` auto-creates `v3.5.0-preview.1` if missing → `publish.yml` publishes (~2–3 min).
   Or push the tag manually before merge:
   ```bash
   git tag v3.5.0-preview.1
   git push origin v3.5.0-preview.1
   ```
6. Wait for the `publish.yml` workflow to finish (~2–3 min).
7. Bump consumers:
   ```bash
   ./scripts/bump-contracts.sh 3.5.0-preview.1
   ```
8. Commit `package.json` + lockfile in `plassy-backend`, `plassy-scraper`, and `plassy-app`.
9. Open PRs for backend/scraper/app → `main`.
10. Human merge → preview deploy via GitHub Actions.

### Production release

1. Bump `package.json` to stable version (e.g. `3.5.0`) on `main`.
2. Create GitHub Release `v3.5.0` → `publish.yml` publishes stable to GitHub Packages.
3. Bump consumers with stable version, merge, then tag app/backend/scraper repos for coordinated prod deploy.

### Accepted tags

The `publish.yml` workflow publishes on:

- `v*.*.*` — stable releases (production)
- `v*.*.*-preview.*` — preview prereleases

### Pinning

Always pin the exact version: `"@plassy-app/api-contracts": "3.5.0-preview.1"` (not `^`).

## Backend and scraper

- Integration branch: `main`.
- Push to `main` → GitHub Action `deploy-preview.yml` → `railway up --environment preview`.
- Tag `vX.Y.Z` → GitHub Action `deploy-production.yml` → `railway up --environment production`.
- The preview backend talks to the scraper via `SCRAPER_URL` (internal Railway network) and `SCRAPER_INTERNAL_TOKEN` (shared between both preview services).
- `APPSTORE_VERIFICATION_ENV=sandbox` on the preview backend (TestFlight / sandbox purchases).

### Required GitHub secrets (backend + scraper)

| Secret                       | Source                                                              |
| ---------------------------- | ------------------------------------------------------------------- |
| `RAILWAY_TOKEN_PREVIEW`      | Railway project token scoped to **preview** environment             |
| `RAILWAY_TOKEN_PRODUCTION`   | Railway project token scoped to **production** environment          |

Create tokens: Railway dashboard → Project → Settings → Tokens.

### API coordination

| Change type                          | Order                                             |
| ------------------------------------ | ------------------------------------------------- |
| Optional field added                 | Backend deploy then app update — usually tolerant |
| Required field / stricter validation | **Backend first**, then app                       |
| New route                            | Backend deploy, then app with new client          |
| Field removed / renamed              | Coordinated deploy immediately                    |

## Mobile app (`plassy-app`)

### Build vs OTA (after merge to `main`)

The preview GitHub Action uses fingerprint detection (same logic as before):

| Situation                                  | Result                              | Tester action           |
| ------------------------------------------ | ----------------------------------- | ----------------------- |
| JS/TS only (screens, logic, API client)    | OTA on channel `preview`            | Reopen the app          |
| Native change or no compatible cloud build | `build` + `submit`                  | Install from TestFlight |

Files that are typically **native** (rebuild required):

- `app.json` / `app.config.js` (plugins, permissions, version)
- `ios/`, `android/`
- Custom Expo plugins (`plugins/`)
- Dependencies with native code (Mapbox, native Sentry config, share extension)
- `runtimeVersion` / `appVersion` bump

### Production release

```bash
gh release create v1.2.3 --title "1.2.3" --notes "..."
```

This triggers `deploy-production.yml` which runs `.eas/workflows/production-deploy.yml`.

### EAS variables (environment `preview`)

Configured on expo.dev → Environment variables → `preview`:

- `NODE_AUTH_TOKEN` + `NPM_TOKEN` (same GitHub PAT, scope `read:packages`) — **required** for `@plassy-app/api-contracts`
- `EXPO_PUBLIC_MAPBOX_ACCESS_TOKEN`
- `EXPO_PUBLIC_GOOGLE_CLIENT_ID_IOS`
- `EXPO_PUBLIC_IOS_IAP_*`
- `EXPO_PUBLIC_BACKEND_URL` (redundant with `eas.json`, same Railway preview value)
- `SENTRY_AUTH_TOKEN` (recommended)

`EXPO_PUBLIC_SSL_PIN_SHA256`: **optional** (absent on preview — pinning disabled, acceptable for testing).

### Available Expo MCP tools

The agent can use the Expo MCP (already authenticated) for:

| Action                        | MCP tool                                                          |
| ----------------------------- | ----------------------------------------------------------------- |
| List / track builds           | `build_list`, `build_info`, `build_logs`                          |
| Trigger a manual build        | `build_run`                                                       |
| Submit to TestFlight          | `build_submit`                                                    |
| Run / track workflow          | `workflow_run`, `workflow_list`, `workflow_info`, `workflow_logs` |
| Validate workflow YAML        | `workflow_validate`                                               |
| TestFlight crashes / feedback | `testflight_crashes`, `testflight_feedback`                       |

**Manual OTA** (if needed outside the workflow): no dedicated MCP tool — use the CLI:

```bash
cd plassy-app
eas update --channel preview --message "..." --non-interactive
```

### Re-run preview deploy manually

```bash
cd plassy-app
gh workflow run preview-deploy.yml
# or
eas workflow:run preview-deploy.yml
```

## Git conventions

### Agent branch naming

```
cursor/<short-description>-7c6d
```

Examples: `cursor/fix-login-7c6d`, `cursor/add-place-filter-7c6d`.

### PRs

- **Always open a draft PR** after committing and pushing — a pushed branch alone is not a complete deliverable.
- Always **draft** unless instructed otherwise.
- One PR per touched repo.
- Clear title in English (repo convention).
- PR body: summary, impacted repos, merge order, testing instructions.

#### Opening PRs in submodules

Code changes live in **submodule repos** (`plassy-app`, `plassy-backend`, etc.), not in the umbrella `Plassy` repo. Run git and PR commands **from inside the submodule**:

```bash
cd plassy-app   # or plassy-backend, plassy-scraper, plassy-contracts
git push -u origin cursor/my-fix-7c6d
gh pr create --draft --base main --head cursor/my-fix-7c6d \
  --title "fix: short description" \
  --body "## Summary"
```

| Repo               | PR base branch |
| ------------------ | -------------- |
| `plassy-app`       | `main`         |
| `plassy-backend`   | `main`         |
| `plassy-scraper`   | `main`         |
| `plassy-contracts` | `main`         |

The umbrella `Plassy` repo only needs a PR when root files change (e.g. `AGENTS.md`, root scripts).

### Umbrella monorepo

After a submodule PR is merged on GitHub, the latest commit already exists on the remote. To update the submodule pointer in the parent repository, **pull** those changes locally inside the submodule — do not push from the submodule.

```bash
cd plassy-app  # or another submodule
git fetch origin
git checkout origin/main
cd ..
git add plassy-app
git commit -m "chore: bump plassy-app submodule (main)"
git push
```

Only do this when explicitly requested for the umbrella repo.

## Expected deliverables per task

At the end of a preview task:

1. **Branches + draft PRs** on each concerned repo — confirm each PR URL before closing the task.
2. **Contracts tag** published if applicable (prerelease version).
3. **Merge instructions**: order when multiple PRs exist (contracts → backend/scraper → app).
4. **After merge** (if requested): verify the GitHub Action / EAS workflow and confirm OTA or TestFlight build.
5. **Testing message**:
   - OTA: "Merge complete — reopen the preview app to fetch the update"
   - Native: "Merge complete — new TestFlight build in ~20 min"
   - Backend: "Preview API redeployed on Railway"

When the user also asked to **create a Linear task**, include the issue URL; follow `.cursor/rules/linear-task-creation.mdc` (French title + description).

## Prohibited actions

| Action                                          | Why                                             |
| ----------------------------------------------- | ----------------------------------------------- |
| `EXPO_PUBLIC_BACKEND_URL` with ngrok in preview | Crash on startup (guard in `lib/api/client.ts`) |
| Preview → `api.plassy.fr`                       | Risk to production data                         |
| `eas build --profile production` for testing    | Reserved for store releases                     |
| `bun link` contracts in CI/EAS                  | Local dev only — use npm publish                |
| Merge without review unless explicitly asked    | Human gate is intentional                       |

## Git / PR troubleshooting

| Error                                                                     | Likely cause                                              | Fix                                                                                                            |
| ------------------------------------------------------------------------- | --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `Resource not accessible by integration` on `gh pr create` in a submodule | Cursor GitHub App not installed on that submodule repo    | Install the app on `Plassy-App/Plassy-App` (and other submodules), or open the PR manually via the compare URL |
| PR tool targets umbrella repo only                                        | `ManagePullRequest` runs against `Plassy`, not submodules | Use `gh pr create` from inside the submodule (`cd plassy-app`)                                                 |
| Railway deploy fails with 401                                             | Missing or wrong `RAILWAY_TOKEN_*` secret                   | Create environment-scoped project token in Railway dashboard                                                   |

Fallback compare URL (replace `<branch>`):

`https://github.com/Plassy-App/Plassy-App/compare/main...<branch>`

## EAS workflow troubleshooting

| Error                                   | Likely cause                                                 | Fix                                                 |
| --------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------- |
| `401` on `@plassy-app/api-contracts`    | Invalid `NODE_AUTH_TOKEN` / `NPM_TOKEN` in EAS `preview` env | Recreate secrets on expo.dev                        |
| Owner mismatch (`sweizeur` vs `plassy`) | `app.json` → `owner` not aligned with Expo org               | `"owner": "plassy"`                                 |
| `No repository found for appId`         | GitHub repo not connected to EAS                             | Connect `Plassy-App/Plassy-App` under org `@plassy` |
| OTA does not apply                      | App installed from a `--local` build                         | Install the cloud preview build via TestFlight      |
| Workflow skips OTA, runs build          | First cloud build or native change                           | Expected — wait for TestFlight                      |

## Linear (issue tracking)

When creating or updating a task, follow **`.cursor/rules/linear-task-creation.mdc`**:

- **Titre et description en français**
- Project `Version 1`, labels (`UX`, `Design`, `Backend`, … — pas `UI`), team Dev/Design
- Linear MCP (`save_issue`, …)

Project board: [Version 1](https://linear.app/plassy/project/version-1-ee36a8c46464)

## References

| File                                                                           | Role                                  |
| ------------------------------------------------------------------------------ | ------------------------------------- |
| `plassy-app/eas.json`                                                          | Preview / production build profiles   |
| `plassy-app/.github/workflows/preview-deploy.yml`                              | Auto preview on push to main          |
| `plassy-app/.github/workflows/deploy-production.yml`                           | Production on release tag             |
| `plassy-backend/.github/workflows/deploy-preview.yml`                          | Railway preview deploy                |
| `plassy-backend/.github/workflows/deploy-production.yml`                       | Railway production deploy             |
| `scripts/single-branch-migration/apply-migration.sh`                           | One-shot migration script             |
| `scripts/bump-contracts.sh`                                                    | Bump consumers after publish          |
| `plassy-contracts/.github/workflows/tag-preview.yml`                           | Auto-tag preview versions on main     |
| `plassy-contracts/.github/workflows/publish.yml`                               | npm publish (stable + preview tags)   |
| `README.md`                                                                    | Monorepo setup, root scripts          |
| [Linear — Version 1](https://linear.app/plassy/project/version-1-ee36a8c46464) | V1 backlog, Dev + Design issues       |

## Quick checklist by task type

### App UI / logic only

- [ ] Branch `cursor/...` from `main` in `plassy-app`
- [ ] Draft PR → `main`
- [ ] Merge → automatic OTA

### Backend only (same contract)

- [ ] Branch from `main` in `plassy-backend` (+ scraper if scraping is impacted)
- [ ] Draft PR → `main`
- [ ] Merge → Railway preview deploy

### Full-stack with contracts

- [ ] PR with `X.Y.Z-preview.N` version on `plassy-contracts` → `main`
- [ ] Wait for npm publish (auto-tag on merge)
- [ ] `bump-contracts.sh` + PRs for backend/scraper/app → `main`
- [ ] Merge backend/scraper first, then app
- [ ] Verify preview deploy

### Native app change

- [ ] PR → `main`
- [ ] Merge → build + TestFlight (not OTA alone)
- [ ] Notify that a new TestFlight build must be installed

### Production release

- [ ] Validate on preview (merge to `main` tested)
- [ ] `gh release create vX.Y.Z` on each touched repo (or monorepo tag)
- [ ] Verify Railway production + EAS production workflows

## Cursor Cloud specific instructions

Durable, non-obvious notes for running this monorepo inside a Cursor Cloud Agent VM (headless Linux). The startup update script already refreshes dependencies (submodule init, `bun install` per repo, contracts build+link, `npm install` for the frontend). Standard commands live in `README.md` and each `package.json`; only the gotchas are listed here.

### What runs on the cloud VM (and what does not)

- **plassy-app is iOS/Android only and does NOT run on the web.** Do not attempt Expo web ("bun run web") as a way to "run" the product — react-native-web is incompatible (e.g. "Appearance.setColorScheme" is missing) and "@rnmapbox/maps" needs a "mapbox-gl" web peer that is intentionally not a dependency. On the VM, validate the app only via individual commands: "bun run --cwd plassy-app typecheck", "bun run --cwd plassy-app test", or "bun run --cwd plassy-app lint" (and the Metro bundler can start). The real run target is a physical device via EAS/TestFlight — see the preview workflow above.
- **Runnable services on the VM:** `plassy-backend` (`:3001`), `plassy-scraper` (`:3002`), `plassy-frontend` (`:3000`). These are what to exercise for end-to-end checks here.

### Private contracts package (`@plassy-app/api-contracts`)

- Consumers (`plassy-backend`, `plassy-scraper`, `plassy-app`) depend on this private GitHub Packages package. The cloud `GH_TOKEN` does **not** have `read:packages`, so registry installs return `401`.
- Local-dev workaround (handled by the update script): build `plassy-contracts` then `bun link` it, and `bun link @plassy-app/api-contracts` inside each consumer before `bun install`. Once linked, `bun install` no longer hits the registry. If a consumer suddenly fails to resolve the package, re-run `bun link @plassy-app/api-contracts` in that folder.

### Backend (`plassy-backend`)

- Local **PostgreSQL 16** and **Redis** are installed in the VM and started with "sudo service postgresql start" and "sudo service redis-server start" (no systemd in the VM, but sysvinit service wrappers are available). DB/user: "plassy" / "plassy", database "plassy".
- The Prisma schema relies on the **`pg_uuidv7`** extension (`uuid_generate_v7()`), which is **not** in stock Postgres — it is installed into the cluster from `fboulnois/pg_uuidv7`. Apply schema with `bunx prisma migrate deploy` (the `init` migration runs `CREATE EXTENSION pg_uuidv7`). Do **not** use `prisma db push` for a fresh DB: it tries to create tables before the extension exists and fails with `function uuid_generate_v7() does not exist`.
- **Boot gotcha:** `src/services/places/enrichment/llm-extractor.ts` constructs the OpenAI client at import time, so the backend **refuses to start without a non-empty `OPENAI_API_KEY`**, even though env validation marks it optional. A placeholder value (e.g. `sk-placeholder-...`) lets it boot; real AI features need a real key.
- `/health` reports `"degraded"` with `redis:"disconnected"` in dev — this is expected (ioredis lazy-connects; Redis is optional in dev). `database:"connected"` is the signal the DB is wired correctly. `GET /api/hello` → `{"ok":true}` is a quick liveness check.
- `.env` files are gitignored and created during setup ("cp .env.example .env"). Minimum to boot: "DATABASE_URL", "NODE_ENV=development", "OPENAI_API_KEY" (placeholder ok), and "SCRAPER_INTERNAL_TOKEN" (to match the scraper).

### Scraper (`plassy-scraper`)

- Boots without browsers, but **actual scraping needs Playwright Chromium**: `cd plassy-scraper && bunx playwright install --with-deps chromium` (installed once in the VM snapshot, not in the update script).
- `/scrape/*` is protected by the `x-scraper-token` header which must equal `SCRAPER_INTERNAL_TOKEN`; the same value must be set in the backend `.env`. Generate with `openssl rand -hex 32`.
- From a datacenter IP, Instagram/TikTok often return bot-wall pages, so OG titles may be generic (e.g. `"TikTok - Make Your Day"`). The pipeline still runs end-to-end; this is a network/IP limitation, not a code error.

# Plassy — Cursor Cloud Agent (VM-only)

Instructions for running this monorepo inside a Cursor Cloud Agent VM (headless Linux). **Local IDE agents can ignore this file** — see `AGENTS.md` for the preview workflow, contracts, and git conventions.

The startup recipe is in `.cursor/environment.json`: submodule init, `bun install`, and Postgres/Redis via `start`.

## What runs on the VM (and what does not)

- **plassy-app is iOS/Android only — not web.** Do not use `bun run web` to validate the product: react-native-web is incompatible (e.g. `Appearance.setColorScheme` is missing) and `@rnmapbox/maps` needs a `mapbox-gl` web peer that is intentionally not a dependency. On the VM, validate the app via `bun run --cwd plassy-app typecheck`, `test`, or `lint`. The real run target is a physical device via EAS/TestFlight (see `AGENTS.md`).
- **Runnable services on the VM:** `plassy-backend` (`:3001`), `plassy-scraper` (`:3002`), `plassy-frontend` (`:3000`).

## Private contracts package (`@plassy-app/api-contracts`)

Consumers (`plassy-backend`, `plassy-scraper`, `plassy-app`) depend on this private GitHub Packages package. The cloud `GH_TOKEN` typically does **not** have `read:packages`, so registry installs return `401`.

**Local-dev workaround** (after clone or when contracts change, before publish):

```bash
cd plassy-contracts
bun install && bun run build
bun link

cd ../plassy-backend && bun link @plassy-app/api-contracts
cd ../plassy-scraper && bun link @plassy-app/api-contracts
cd ../plassy-app && bun link @plassy-app/api-contracts
```

Once linked, `bun install` in consumers no longer hits the registry. If a consumer suddenly fails to resolve the package, re-run `bun link @plassy-app/api-contracts` in that folder. Restart Metro after linking in `plassy-app`.

**Never** use `bun link` in CI/EAS — see `AGENTS.md` → Contracts for the publish/bump workflow.

## Backend (`plassy-backend`)

- **PostgreSQL 16** and **Redis** start via `environment.json` → `start`. Manual fallback: `sudo service postgresql start` and `sudo service redis-server start`. DB/user: `plassy` / `plassy`, database `plassy`.
- The Prisma schema relies on the **`pg_uuidv7`** extension (`uuid_generate_v7()`), installed from `fboulnois/pg_uuidv7`. Apply schema with `bunx prisma migrate deploy` (the `init` migration runs `CREATE EXTENSION pg_uuidv7`). Do **not** use `prisma db push` on a fresh DB — it fails with `function uuid_generate_v7() does not exist`.
- **Boot gotcha:** `src/services/places/enrichment/llm-extractor.ts` constructs the OpenAI client at import time, so the backend **refuses to start without a non-empty `OPENAI_API_KEY`**, even though env validation marks it optional. A placeholder (e.g. `sk-placeholder-...`) lets it boot; real AI features need a real key.
- `/health` reports `"degraded"` with `redis:"disconnected"` in dev — expected (ioredis lazy-connects; Redis is optional in dev). `database:"connected"` means the DB is wired. `GET /api/hello` → `{"ok":true}` is a quick liveness check.
- `.env` files are gitignored. Minimum to boot: `DATABASE_URL`, `NODE_ENV=development`, `OPENAI_API_KEY` (placeholder ok), and `SCRAPER_INTERNAL_TOKEN` (must match scraper).

## Scraper (`plassy-scraper`)

- Boots without browsers, but **actual scraping needs Playwright Chromium**: `cd plassy-scraper && bunx playwright install --with-deps chromium` (one-time per VM; not in the `install` script).
- `/scrape/*` is protected by the `x-scraper-token` header which must equal `SCRAPER_INTERNAL_TOKEN`; the same value must be set in the backend `.env`. Generate with `openssl rand -hex 32`.
- From a datacenter IP, Instagram/TikTok often return bot-wall pages, so OG titles may be generic (e.g. `"TikTok - Make Your Day"`). The pipeline still runs end-to-end; this is a network/IP limitation, not a code error.

## Cursor secrets

**Required:** `GH_TOKEN` or `SUBMODULES_PAT` with `repo` scope for private submodule clone (`scripts/init-submodules.sh`). Without it, submodule init fails.

Optional: `read:packages` on the same token avoids needing `bun link` for contracts — but `bun link` remains the documented workaround when the token lacks that scope.

# FromFeed workspace (meta-repository)

This repository groups four existing GitHub projects as **Git submodules**. It adds shared root tooling only (Husky, lint-staged, VS Code recommendations)—no duplicate history for application code.

## Repositories

| Directory | Remote |
|-----------|--------|
| `fromfeed-app` | `git@github.com:Sweizeur/FromFeed-App.git` |
| `fromfeed-backend` | `git@github.com:Sweizeur/Fromfeed-Backend.git` |
| `fromfeed-contracts` | `git@github.com:Sweizeur/fromfeed-contracts.git` |
| `fromfeed-frontend` | `git@github.com:Sweizeur/FromFeed.git` |

Create **one new empty GitHub repo** for this umbrella (for example `Sweizeur/fromfeed-workspace`). Do **not** reuse an existing project URL—the landing site already uses `Sweizeur/FromFeed.git` as `fromfeed-frontend`.

## Clone

```bash
git clone --recurse-submodules git@github.com:Sweizeur/<YOUR_META_REPO>.git
cd <YOUR_META_REPO>
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

## Daily workflow

1. Work inside a submodule as usual (`git pull`, commit, push to **that** repo’s `origin`).
2. When you advance a submodule commit and want the umbrella repo to record the new pin: from the **workspace root**, `git add fromfeed-app` (etc.), commit, and push the meta-repo.

```bash
cd fromfeed-backend
# … commit & git push origin main
cd ..
git add fromfeed-backend
git commit -m "chore: bump backend submodule"
git push origin main
```

## Install (root)

```bash
pnpm install
```

---

_Dépôt parapluie : chaque sous-projet reste indépendant sur GitHub ; ce repo ne fait que référencer des commits précis._

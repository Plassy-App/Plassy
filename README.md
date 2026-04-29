# Plassy workspace (meta-repository)

Parent repo: **`git@github.com:Sweizeur/FromFeed.git`**

This umbrella repository groups four GitHub projects as **Git submodules**. It only adds shared root tooling (Husky, lint-staged, VS Code recommendations)—no duplicate history for application code.

## Submodules

| Directory | Remote |
|-----------|--------|
| `fromfeed-app` | `git@github.com:Sweizeur/Plassy-App.git` |
| `fromfeed-backend` | `git@github.com:Sweizeur/Plassy-Backend.git` |
| `fromfeed-contracts` | `git@github.com:Sweizeur/Plassy-Contracts.git` |
| `fromfeed-frontend` | `git@github.com:Sweizeur/Plassy-Fontend.git` |

On disk the folders keep the `fromfeed-*` names; each submodule’s `origin` points to the **Plassy-* / Plassy-Contracts / Plassy-Fontend** repos above.

## Clone

```bash
git clone --recurse-submodules git@github.com:Sweizeur/FromFeed.git
cd FromFeed
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

## Daily workflow

1. Work inside a submodule as usual (`git pull`, commit, push to **that** repo’s `origin`).
2. When you advance a submodule commit and want the umbrella repo to record the new pin: from the **workspace root**, `git add fromfeed-app` (etc.), commit, and push **FromFeed** (parent).

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

_Dépôt parapluie (**FromFeed** sur GitHub) : chaque sous-projet reste indépendant ; ce repo ne fait que référencer des commits précis._

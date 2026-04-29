# Plassy — meta-repository (workspace)

**Umbrella repo:** [`git@github.com:Sweizeur/Plassy.git`](https://github.com/Sweizeur/Plassy)

This repository groups four GitHub projects as **Git submodules**. It only adds shared root tooling (Husky, lint-staged, VS Code recommendations)—no duplicate history for application code.

## Submodules

| Directory          | Repository                                     |
| ------------------ | ---------------------------------------------- |
| `plassy-app`       | `git@github.com:Sweizeur/Plassy-App.git`       |
| `plassy-backend`   | `git@github.com:Sweizeur/Plassy-Backend.git`   |
| `plassy-contracts` | `git@github.com:Sweizeur/Plassy-Contracts.git` |
| `plassy-frontend`  | `git@github.com:Sweizeur/Plassy-Fontend.git`   |

_(The frontend marketing site remote name on GitHub is `Plassy-Fontend`.)_

## Clone

```bash
git clone --recurse-submodules git@github.com:Sweizeur/Plassy.git
cd Plassy
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

### Access

Each submodule is a **separate** private repository on GitHub. Being invited on **Plassy** alone does **not** grant clone rights to the submodules: each collaborator needs access to every repo they must pull (App, Backend, Contracts, Frontend), or submodule clone/update will fail with permission errors.

## Daily workflow

1. Work inside a submodule as usual (`git pull`, commit, push to **that** repo’s `origin`).
2. When you advance a submodule commit and want this umbrella repo to record the new pin: from the **workspace root**, `git add plassy-app` (etc.), commit, and push **Plassy** (parent).

```bash
cd plassy-backend
# … commit & git push origin main
cd ..
git add plassy-backend
git commit -m "chore: bump backend submodule"
git push origin main
```

## Install (root)

```bash
pnpm install
```

Hooks (`lint-staged`) run from this root when you commit here.

---

_Dépôt parapluie : chaque sous-projet reste indépendant sur GitHub ; ce repo ne fait que référencer des commits précis._

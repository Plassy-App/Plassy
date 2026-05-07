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
bun install
```

Hooks (`lint-staged`) run from this root when you commit here.

## Scripts (tout depuis la **racine**)

Toujours `cd` dans le repo parapluie.

- **`bun run help`** — imprime tous les scripts, groupés (**`bun run help app`** filtre par préfixe : `app`, `backend`, `sonar`, etc.).
- Raccourcis fréquents : **`bun run dev:app`**, **`dev:backend`**, **`dev:web`**.

| Commande                                        | Rôle                                            |
| ----------------------------------------------- | ----------------------------------------------- |
| `bun run app:start`                             | Metro / Expo                                    |
| `bun run app:start:dev`                         | Expo + dev client                               |
| `bun run app:build:dev` / `:simulator`          | `expo run:ios` (souvent simulateur par défaut)  |
| `bun run app:build:dev:device -- -d <UDID>`     | Build debug sur l’iPhone                        |
| `bun run app:build:release` / `:simulator`      | `expo run:ios --configuration Release`          |
| `bun run app:build:release:device -- -d <UDID>` | Idem release sur appareil                       |
| `bun run app:run:android`                       | `expo run:android`                              |
| `bun run app:prebuild` / `app:prebuild:clean`   | Prebuild natif                                  |
| `bun run app:ios:pods`                          | `pod install` + sync extension                  |
| `bun run app:lint` / `app:test`                 | Qualité app                                     |
| `bun run backend:dev` / `backend:start`         | Backend Bun                                     |
| `bun run backend:build`                         | Prisma generate + `tsc` (hors fichiers de test) |
| `bun run backend:db:*`                          | Prisma                                          |
| `bun run contracts:build` / `frontend:dev` / …  | Autres paquets                                  |

EAS cloud : `bun run app:eas:build:*`. Les sous-`package.json` ne déclarent plus les scripts de dev globaux (sauf hooks requis, ex. `eas-build-post-install` dans l’app) ; en revanche **chaque sous-module a son propre Husky** : après `bun install` / `npm install` **dans ce dossier**, un `git commit` y lance `lint-staged` + ESLint sur les fichiers stagés.

---

_Dépôt parapluie : chaque sous-projet reste indépendant sur GitHub ; ce repo ne fait que référencer des commits précis._

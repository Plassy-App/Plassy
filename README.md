# Plassy — dépôt parapluie (espace de travail)

**Dépôt parent :** [`git@github.com:Sweizeur/Plassy.git`](https://github.com/Sweizeur/Plassy)

Ce dépôt regroupe quatre projets GitHub en **sous-modules Git**. Il apporte uniquement l’outilage partagé à la racine (Husky, lint-staged, recommandations VS Code) ; l’historique du code applicatif reste dans chaque sous-module.

## Sous-modules

| Dossier            | Dépôt                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------- |
| `plassy-app`       | `git@github.com:Sweizeur/Plassy-App.git`                                              |
| `plassy-backend`   | `git@github.com:Sweizeur/Plassy-Backend.git`                                          |
| `plassy-contracts` | `git@github.com:Sweizeur/Plassy-Contracts.git`                                        |
| `plassy-frontend`  | `git@github.com:Sweizeur/Plassy-Fontend.git`                                          |
| `plassy-scraper`   | _Local pour l'instant — à promouvoir en `git@github.com:Sweizeur/Plassy-Scraper.git`_ |

_(Le dépôt du site marketing côté front s’appelle sur GitHub `Plassy-Fontend`.)_

## Cloner

```bash
git clone --recurse-submodules git@github.com:Sweizeur/Plassy.git
cd Plassy
```

Si vous avez déjà cloné sans les sous-modules :

```bash
git submodule update --init --recursive
```

### Accès

Chaque sous-module est un **dépôt privé distinct** sur GitHub. Être invité sur **Plassy** seul **ne donne pas** le droit de cloner les sous-modules : chaque collaborateur doit avoir accès à tous les dépôts qu’il doit tirer (App, Backend, Contracts, Frontend), sinon le clonage ou la mise à jour des sous-modules échouera pour cause de permissions.

## Flux de travail au quotidien

1. Travailler dans un sous-module comme d’habitude (`git pull`, commits, poussées vers **`origin` de ce dépôt**).
2. Quand vous avancez le commit pointé par un sous-module et que vous voulez que le dépôt parapluie enregistre cette révision : depuis la **racine de l’espace**, `git add plassy-app` (etc.), puis commit et poussée sur **Plassy** (parent).

```bash
cd plassy-backend
# … commits puis git push origin main
cd ..
git add plassy-backend
git commit -m "chore: mise à jour du sous-module backend"
git push origin main
```

## Installation (racine)

```bash
bun install
```

Les hooks (`lint-staged`) s’exécutent depuis cette racine lorsque vous faites un commit **ici**.

## Scripts (toujours depuis la **racine** du parapluie)

- **`bun run help`** — affiche tous les scripts, regroupés par préfixe. **`bun run help app`** (ou `backend`, `sonar`, etc.) **filtre** par nom ou préfixe.
- **`prepare`** (`husky`) — exécuté automatiquement après `bun install` à la racine ; pas besoin de l’appeler à la main.

### Espace de travail (racine)

| Commande              | Rôle                                                     |
| --------------------- | -------------------------------------------------------- |
| `bun run dev:app`     | Raccourci vers `app:start:dev`                           |
| `bun run dev:backend` | Raccourci vers `backend:dev`                             |
| `bun run dev:web`     | Raccourci vers `frontend:dev`                            |
| `bun run format`      | Lance Prettier sur le dépôt (respecte `.prettierignore`) |
| `bun run lint`        | Enchaîne les lints app, backend, contracts et frontend   |

### Application mobile (`plassy-app`)

| Commande                     | Rôle                                                                                                       |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `bun run app:start`          | Démarre Expo (serveur Metro)                                                                               |
| `bun run app:start:dev`      | Expo avec client de développement                                                                          |
| `bun run app:web`            | Expo pour la cible web                                                                                     |
| `bun run app:lint`           | `expo lint`                                                                                                |
| `bun run app:test`           | Jest                                                                                                       |
| `bun run app:test:watch`     | Jest en mode surveillance                                                                                  |
| `bun run app:prebuild`       | `expo prebuild` (génération native)                                                                        |
| `bun run app:prebuild:clean` | `expo prebuild --clean`                                                                                    |
| `bun run app:ios:pods`       | `pod install` dans `plassy-app/ios`, puis synchronisation du numéro de build de l’extension de partage iOS |

Convention des scripts **`app:build`** (racine du mono‑repo) :

`app:build:<ios|android>:<expo|eas>:<dev|preview|prod>:…`

- **`expo`** : compilation **locale** avec `expo run:*`.
- **`eas`** : build EAS, puis **`:sim`** ou **`:device`** selon la cible, puis **`:cloud`** ou **`:local`**. Un script **sans** `:cloud`/`:local` reroute vers la variante **cloud**.
- **`prod`** côté Expo remplace l’ancien libellé **`release`** (configuration iOS Release / variante Gradle `release`).
- **`:sim`** : simulateur iOS ou **émulateur** Android. **`:device`** : appareil physique. Les profils EAS **preview** et **production** n’ont pas de variante simulateur dans `eas.json` ; on utilise **`:device`**.

#### Expo (`expo run:*`, toujours local)

| Commande                                     | Rôle                                                                             |
| -------------------------------------------- | -------------------------------------------------------------------------------- |
| `bun run app:build:ios:expo:dev:sim`         | iOS **debug**, simulateur (`expo run:ios`)                                       |
| `bun run app:build:ios:expo:dev:device`      | iOS **debug**, appareil (`--device` ; options suppl. : `-- -d <UDID>` si besoin) |
| `bun run app:build:ios:expo:prod:sim`        | iOS **Release**, simulateur                                                      |
| `bun run app:build:ios:expo:prod:device`     | iOS **Release**, appareil                                                        |
| `bun run app:build:android:expo:dev:sim`     | Android **debug**, émulateur (`expo run:android`)                                |
| `bun run app:build:android:expo:dev:device`  | Android **debug**, appareil ou cible explicite (`--device`)                      |
| `bun run app:build:android:expo:prod:sim`    | Android **`--variant release`**, émulateur                                       |
| `bun run app:build:android:expo:prod:device` | Android **`--variant release --device`**                                         |

#### EAS (`eas build`, cloud ou `--local`)

| Commande                                             | Rôle                                                                       |
| ---------------------------------------------------- | -------------------------------------------------------------------------- |
| `bun run app:build:ios:eas:dev:sim`                  | Profil **development-simulator**, cloud (raccourci)                        |
| `bun run app:build:ios:eas:dev:sim:cloud`            | Idem, explicite                                                            |
| `bun run app:build:ios:eas:dev:sim:local`            | **development-simulator**, **`--local`**                                   |
| `bun run app:build:ios:eas:dev`                      | Profil **development** (install appareil via build EAS), cloud (raccourci) |
| `bun run app:build:ios:eas:dev:cloud`                | Idem, explicite                                                            |
| `bun run app:build:ios:eas:dev:local`                | **development**, **`--local`**                                             |
| `bun run app:build:ios:eas:preview`                  | **preview** iOS, cloud (raccourci)                                         |
| `bun run app:build:ios:eas:preview:cloud`            | Idem, explicite                                                            |
| `bun run app:build:ios:eas:preview:local`            | **preview**, **`--local`**                                                 |
| `bun run app:build:ios:eas:prod`                     | **production** iOS, cloud (raccourci)                                      |
| `bun run app:build:ios:eas:prod:cloud`               | Idem, explicite                                                            |
| `bun run app:build:ios:eas:prod:local`               | **production**, **`--local`**                                              |
| `bun run app:build:ios:eas:prod:auto-submit`         | Production + **`--auto-submit`** (raccourci, défaut : local)               |
| `bun run app:build:ios:eas:prod:auto-submit:cloud`   | Idem, build cloud puis soumission automatique                              |
| `bun run app:build:ios:eas:prod:auto-submit:local`   | **`--local --auto-submit`**                                                |
| `bun run app:build:android:eas:dev:device`           | **development** Android, cloud (raccourci)                                 |
| `bun run app:build:android:eas:dev:device:cloud`     | Idem, explicite                                                            |
| `bun run app:build:android:eas:dev:device:local`     | **development** Android, **`--local`**                                     |
| `bun run app:build:android:eas:preview:device`       | **preview** Android, cloud (raccourci)                                     |
| `bun run app:build:android:eas:preview:device:cloud` | Idem, explicite                                                            |
| `bun run app:build:android:eas:preview:device:local` | **preview**, **`--local`**                                                 |
| `bun run app:build:android:eas:prod:device`          | **production** Android, cloud (raccourci)                                  |
| `bun run app:build:android:eas:prod:device:cloud`    | Idem, explicite                                                            |
| `bun run app:build:android:eas:prod:device:local`    | **production**, **`--local`**                                              |
| `bun run app:build:android:eas:prod:playstore`       | Production + **`--auto-submit`** vers Play Console (cloud, raccourci)      |
| `bun run app:build:android:eas:prod:playstore:cloud` | Idem, explicite                                                            |
| `bun run app:build:android:eas:prod:playstore:local` | **`--local --auto-submit`**                                                |

#### EAS Submit (soumission seule)

`app:submit:ios:eas:cloud` cible la **dernière build iOS chez Expo** (`--latest`). `app:submit:ios:eas:local` sert pour une **IPA locale** : `bun run app:submit:ios:eas:local -- --path ./CheminVers/MaApp.ipa`. **`app:submit:ios:eas`** est un raccourci vers **`:cloud`**.

`app:submit:android:eas` / **`:cloud`** / **`:local`** font la même chose pour **Android** (AAB/APK : **`--path`** en local). Ajoutez d’autres options après `--` (`--output`, `--id`, etc.).

| Commande                               | Rôle                                                       |
| -------------------------------------- | ---------------------------------------------------------- |
| `bun run app:submit:ios:eas`           | Submit production, **dernière build** (`--latest`)         |
| `bun run app:submit:ios:eas:cloud`     | Idem, explicite                                            |
| `bun run app:submit:ios:eas:local`     | IPA sur disque (passer **`--path`**, etc.)                 |
| `bun run app:submit:android:eas`       | Submit production Android, **dernière build** (`--latest`) |
| `bun run app:submit:android:eas:cloud` | Idem, explicite                                            |
| `bun run app:submit:android:eas:local` | AAB/APK sur disque (passer **`--path`**, etc.)             |

### Microservice scraper (`plassy-scraper`)

Service Bun + Playwright dédié au scraping TikTok / Instagram, **isolé du backend** afin qu'une éventuelle RCE Chromium n'expose pas les secrets applicatifs (DB, OpenAI, S3, Apple IAP). Communique avec le backend via le réseau privé Railway et un token partagé `SCRAPER_INTERNAL_TOKEN`.

Voir `plassy-scraper/README.md` pour les détails (API HTTP, déploiement, threat model).

| Commande                                 | Rôle                                                |
| ---------------------------------------- | --------------------------------------------------- |
| `cd plassy-scraper && bun run dev`       | Démarrer le scraper en local (port 3002 par défaut) |
| `cd plassy-scraper && bun run typecheck` | `tsc --noEmit`                                      |

### Backend (`plassy-backend`)

| Commande                      | Rôle                                               |
| ----------------------------- | -------------------------------------------------- |
| `bun run backend:dev`         | Lance le serveur Bun avec rechargement (`--watch`) |
| `bun run backend:start`       | Lance le serveur Bun sans surveillance             |
| `bun run backend:build`       | `prisma generate` puis `tsc --noEmit`              |
| `bun run backend:lint`        | ESLint sur `src`                                   |
| `bun run backend:typecheck`   | `tsc --noEmit`                                     |
| `bun run backend:test`        | Jest                                               |
| `bun run backend:test:watch`  | Jest en mode surveillance                          |
| `bun run backend:db:generate` | `prisma generate`                                  |
| `bun run backend:db:migrate`  | `prisma migrate dev`                               |
| `bun run backend:db:push`     | `prisma db push`                                   |
| `bun run backend:db:studio`   | `prisma studio`                                    |

### Contrats partagés (`plassy-contracts`)

| Commande                      | Rôle                                            |
| ----------------------------- | ----------------------------------------------- |
| `bun run contracts:build`     | Compilation TypeScript (`tsc -p tsconfig.json`) |
| `bun run contracts:clean`     | Supprime le dossier `dist`                      |
| `bun run contracts:typecheck` | `tsc --noEmit`                                  |
| `bun run contracts:lint`      | ESLint sur `src`                                |

### Site Next.js (`plassy-frontend`)

| Commande                 | Rôle         |
| ------------------------ | ------------ |
| `bun run frontend:dev`   | `next dev`   |
| `bun run frontend:build` | `next build` |
| `bun run frontend:start` | `next start` |
| `bun run frontend:lint`  | ESLint       |

### Analyse Sonar (local, variables dans `.env`)

Les commandes chargent `.env` via `dotenv` et appellent l’outil en ligne de commande `sonar` dans le sous-module concerné. Ajuster `SONAR_HOST_URL` et les jetons par projet si besoin.

| Commande                         | Rôle                                   |
| -------------------------------- | -------------------------------------- |
| `bun run sonar:plassy-app`       | Analyse du sous-module app             |
| `bun run sonar:plassy-backend`   | Analyse du backend                     |
| `bun run sonar:plassy-contracts` | Analyse des contrats                   |
| `bun run sonar:plassy-frontend`  | Analyse du front                       |
| `bun run sonar:all`              | Enchaîne les quatre analyses ci-dessus |

### Remarques

Les **sous-`package.json`** ne redéclarent en général plus les scripts de développement « globaux » (sauf ceux requis par des outils, par ex. `eas-build-post-install` dans l’app). En revanche **chaque sous-module peut avoir son propre Husky** : après `bun install` ou `npm install` **dans ce dossier**, un `git commit` y exécute `lint-staged` et le lint ESLint sur les fichiers stagés.

---

_Dépôt parapluie : chaque sous-projet reste autonome sur GitHub ; ce dépôt ne fait qu’enregistrer des références de commits précis._

# EFoot Market SN

Super-app eFootball pour le Sénégal : marketplace d'achat/vente de comptes eFootball avec séquestre (Phase 1 MVP).

- **Frontend** : Flutter (Riverpod, go_router) — `mobile/`
- **Backend** : FastAPI + PostgreSQL — `backend/`
- **Monnaie** : FCFA (XOF), uniquement des entiers

## Prérequis

| Outil | Usage |
|---|---|
| Docker + Docker Compose | Lancer l'API + PostgreSQL |
| Python 3.12+ | Tests backend en local (optionnel si Docker) |
| Flutter SDK | Compiler et analyser l'app mobile/web |

## Backend

### Lancer avec Docker (recommandé)

```bash
cd backend
copy .env.example .env
# Édite .env : mets une SECRET_KEY longue et aléatoire
docker compose up --build
```

L'API démarre sur <http://localhost:8000/docs> (Swagger).

À la première exécution, les migrations Alembic créent le schéma.

### Créer un compte admin

```bash
cd backend
docker compose exec api python scripts/seed_admin.py
```

Variables d'admin (optionnelles) : `ADMIN_EMAIL`, `ADMIN_USERNAME`, `ADMIN_PASSWORD`.

### Tests pytest (sans Docker)

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # macOS/Linux
pip install -r requirements.txt
pytest -v
```

### Variables d'environnement (`.env`)

Voir `backend/.env.example`. Ne jamais commiter `.env`.

| Variable | Rôle |
|---|---|
| `SECRET_KEY` | Signature JWT (obligatoire en prod) |
| `COMMISSION_RATE` | Taux de commission défaut (0.08 = 8 %) |
| `AUTO_RELEASE_HOURS` | Délai de confirmation acheteur (72 h) |
| `DATABASE_URL` | Chaîne PostgreSQL |
| `PAYTECH_*` | Clés PayTech (Wave / Orange Money) |

## Machine à états des commandes

```
CREATED → PAID_ESCROW → ACCESS_TRANSFERRED → CONFIRMED_BY_BUYER → RELEASED_TO_SELLER
                │                │
                └── DISPUTED ◄───┘  (acheteur ou vendeur)
                       │
         admin: REFUNDED ou RELEASED_TO_SELLER
```

- Interdiction d'acheter sa propre annonce (côté serveur).
- Auto-release 72 h après `ACCESS_TRANSFERRED` (job APScheduler + `POST /api/v1/orders/process-auto-releases`).
- Un litige ouvert bloque la libération auto.
- Commission calculée côté serveur à la libération (`round()` arithmétique décimale).
- Le serveur ne stocke **jamais** les identifiants de compte eFootball.

## API (aperçu)

| Méthode | Route | Description |
|---|---|---|
| POST | `/api/v1/auth/register` | Inscription (buyer / seller) |
| POST | `/api/v1/auth/login` | Connexion (rate limitée) |
| POST | `/api/v1/auth/refresh` | Rotation des tokens |
| GET | `/api/v1/listings` | Recherche / filtres |
| POST | `/api/v1/listings` | Créer une annonce (seller) |
| POST | `/api/v1/orders` | Créer une commande |
| POST | `/api/v1/orders/{id}/pay` | Paiement séquestre (mock) |
| POST | `/api/v1/orders/{id}/transfer-access` | Vendeur : accès remis |
| POST | `/api/v1/orders/{id}/confirm` | Acheteur : confirme → libération |
| POST | `/api/v1/orders/{id}/dispute` | Ouvrir un litige |
| POST | `/api/v1/orders/{id}/resolve` | Admin : refund / release |
| GET/POST | `/api/v1/orders/{id}/messages` | Chat (participants + admin) |
| POST | `/api/v1/webhooks/paytech` | Webhook PayTech (signature HMAC) |

Swagger complet : <http://localhost:8000/docs>

## Frontend (Flutter)

```bash
cd mobile
flutter create . --platforms=web,android,ios   # une seule fois (génère android/, ios/, web/)
flutter pub get
flutter analyze
flutter test
```

### Lancer l'app (backend démarré)

```bash
# Chrome / web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

# Émulateur Android
flutter run -d emulator --dart-define=API_BASE_URL=http://10.0.2.2:8000

# iOS simulateur
flutter run -d simulator --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Analyse statique

```bash
cd mobile
flutter analyze
flutter test
```

### Écrans inclus

| Écran | Route |
|---|---|
| Connexion | `/login` |
| Inscription | `/register` |
| Marketplace + filtres | `/` |
| Détail annonce + achat | `/listings/:id` |
| Créer une annonce | `/sell` |
| Mes commandes (achats/ventes) | `/orders` |
| Détail commande + actions statut | `/orders/:id` |
| Chat commande | `/orders/:id/chat` |
| Profil / logout | `/profile` |

Architecture feature-first : `data` (API) → `application` (Riverpod) → `domain` (modèles) → `presentation` (écrans).
Tokens stockés via `shared_preferences` (MVP) ; en production mobile, migrer vers `flutter_secure_storage`.
Aucun secret dans le code Flutter — uniquement `--dart-define=API_BASE_URL`.

## Structure du dépôt

```
EFOOTBALL/
├── backend/          # FastAPI + PostgreSQL + Alembic + pytest
├── mobile/           # Flutter (web + Android + iOS)
└── README.md
```

## Sécurité

- Tout le sensible (paiements, séquestre, commissions, rôles, transitions) est vérifié côté serveur.
- Aucune clé API dans le code Flutter.
- `.env` non versionné ; `.env.example` documenté.
- Rate limiting sur `/auth/login` et `/auth/register`.
- Webhook PayTech : signature comparée avec `hmac.compare_digest`, traitement idempotent.

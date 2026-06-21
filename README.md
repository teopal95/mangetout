# Mangetout

A shared wishlist app for couples. Each partner adds items — links, photos, notes — and both browse a live feed, filter by category, and mark things as done.

**Flutter → Spring Boot REST API → MongoDB**, containerised with Docker Compose and deployed to the cloud.

---

## Live deployment

| Service | Provider | URL |
|---|---|---|
| REST API | Render (free tier) | `https://mangetout.onrender.com` |
| Database | MongoDB Atlas (M0 free) | `cluster0.ganec34.mongodb.net` |

The backend runs fully in the cloud — no local server needed. The Android APK points directly to the Render URL and works from any network.

> **Note:** Render's free tier spins down after 15 minutes of inactivity. The first request after idle takes ~30 seconds to wake the service up; subsequent requests are instant.

---

## Stack

| Layer | Technology |
|---|---|
| API | Spring Boot 3.2 · Java 17 · Spring Security (JWT/JJWT) |
| Database | MongoDB 7 (Atlas in production) |
| Mobile | Flutter 3 · Provider · GoRouter · Dio |
| Auth | Stateless JWT — issued at login, validated per-request |
| Infrastructure | Docker Compose (multi-stage image build) · Render · MongoDB Atlas |

---

## Features

- **JWT authentication** — register, login, sessions persisted via `flutter_secure_storage`
- **Couple linking** — generate an invite code (7-day expiry), partner enters it to merge accounts; accepter's solo items are deleted and both share one wishlist
- **Shared wishlist** — items scoped to the couple; solo fallback before linking
- **Categories** — customisable, seeded with 6 defaults on first start
- **Link previews** — paste any URL and Jsoup scrapes `og:image` / `og:title` automatically
- **File upload** — pick a photo; stored on the server, served over HTTP at `/uploads/**`
- **Profile page** — change display name, set avatar, sign out

---

## Deploying your own instance

### 1. MongoDB Atlas (database)

1. Create a free M0 cluster at [mongodb.com/atlas](https://www.mongodb.com/atlas)
2. Add a database user and whitelist `0.0.0.0/0` under Network Access
3. Copy the connection string:
   ```
   mongodb+srv://<user>:<password>@<cluster>.mongodb.net/mangetoutdb?retryWrites=true&w=majority
   ```

### 2. Render (backend)

1. Create a new **Web Service** at [render.com](https://render.com) connected to this repo
2. Render detects `render.yaml` automatically
3. Set these environment variables in the Render dashboard:
   - `SPRING_DATA_MONGODB_URI` — your Atlas connection string
   - `APP_BASE_URL` — your Render service URL (e.g. `https://your-app.onrender.com`)
4. Deploy — first build takes ~5 minutes

### 3. Flutter app

Update `serverBase` in [frontend/lib/config/api_config.dart](frontend/lib/config/api_config.dart) to your Render URL, then build:

```bash
cd frontend
flutter build apk --release
```

---

## Running locally

### Prerequisites

- Docker Desktop
- Flutter SDK

### Backend

```bash
docker compose up --build -d
```

API available at `http://localhost:8080`.

### Flutter app

```bash
cd frontend
flutter pub get
flutter run
```

---

## API reference

All endpoints except `/api/auth/*` require `Authorization: Bearer <token>`.

### Auth

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/auth/register` | Create account |
| `POST` | `/api/auth/login` | Get JWT |

### Users

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/users/me` | Get profile (username, email, avatarUrl) |
| `PATCH` | `/api/users/me` | Update username and/or avatarUrl |

### Wishlist items

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/items` | List items — optional `?category=slug&status=WANTED` |
| `POST` | `/api/items` | Create item (triggers link preview fetch if URL provided) |
| `GET` | `/api/items/{id}` | Get item |
| `PATCH` | `/api/items/{id}/status` | Toggle `WANTED` ↔ `DONE` |
| `DELETE` | `/api/items/{id}` | Delete item |

### Categories

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/categories` | List all categories |
| `GET` | `/api/categories/{slug}` | Get one category |
| `POST` | `/api/categories` | Create category |
| `DELETE` | `/api/categories/{id}` | Delete category |

### Couple / invite

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/invite/status` | Link status; includes `inviteToken` if pending |
| `POST` | `/api/invite/generate` | Generate invite token |
| `GET` | `/api/invite/qr` | QR code PNG for the current token |
| `POST` | `/api/invite/accept/{token}` | Link accounts; deletes accepter's solo items |

### Files

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/files/upload` | Upload image; returns `{ "url": "..." }` |

---

## Tests

```bash
./mvnw test
```

26 unit tests across auth, invite-linking, and wishlist item service logic.

---

## Project structure

```
src/main/java/com/mangetout/
  config/       Security, JWT filter, CORS, file-serving, data seed
  controller/   REST controllers
  dto/          Request / response records
  model/        MongoDB documents (User, Category, WishlistItem, Couple)
  repository/   Spring Data interfaces
  service/      Business logic (Auth, Category, Item, Invite, FileStorage, LinkPreview)

frontend/lib/
  config/       API endpoint constants
  models/       Dart data classes
  providers/    Auth state (ChangeNotifier)
  screens/      Login, Register, Home, Feed, Category, Invite, Profile, AddItem
  services/     HTTP clients (AuthService, WishlistService)
  widgets/      Shared UI components (ItemRow)
```

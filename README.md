# Mangetout

A shared wishlist app for couples. Each partner adds items — links, photos, notes — and both browse a live feed, filter by category, and mark things as done.

**Flutter → Spring Boot REST API → MongoDB**, containerised with Docker Compose.

---

## Stack

| Layer | Technology |
|---|---|
| API | Spring Boot 3.2 · Java 17 · Spring Security (JWT/JJWT) |
| Database | MongoDB 7 |
| Mobile | Flutter 3 · Provider · GoRouter · Dio |
| Auth | Stateless JWT — issued at login, validated per-request |
| Infrastructure | Docker Compose (multi-stage image build) |

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

## Running locally

### Prerequisites

- Docker Desktop
- Flutter SDK (for the mobile app)

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

Targets `localhost:8080` by default. To run on a physical device, update `ApiConfig.serverBase` in [frontend/lib/config/api_config.dart](frontend/lib/config/api_config.dart) to your machine's LAN IP.

### Without Docker

```bash
# Requires a local MongoDB instance on port 27017
./mvnw spring-boot:run
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

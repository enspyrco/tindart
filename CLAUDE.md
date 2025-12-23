# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TindArt is a Flutter/Dart mobile app with a Tinder-like interface for discovering and rating artwork. Users swipe through cards to like/dislike art, comment on images, and maintain profiles. Backend is Firebase (Auth, Firestore, Storage, Cloud Functions).

## Common Commands

### Flutter (from project root)

```bash
flutter pub get              # Install dependencies
flutter run                  # Run app
flutter test                 # Run all tests
flutter test test/home_screen_test.dart  # Run single test file
flutter analyze              # Static analysis
dart format .                # Format code
```

### Cloud Functions (from functions/ directory)

```bash
npm install                  # Install dependencies
npm test                     # Run tests
npm run lint                 # Lint code
npm run build                # Build TypeScript
npm run serve                # Local emulator
npm run deploy               # Deploy to Firebase
```

### Local Development with Firebase Emulator

```bash
firebase emulators:start
flutter run --dart-define=USE_FIREBASE_EMULATOR=true  # Auto-signs in as test@example.com
```

## Architecture

### Service Locator Pattern

Services are registered in `main.dart` and accessed globally via `locate<ServiceType>()`:

- `AuthService` - Firebase authentication (Google/Apple sign-in)
- `UsersService` - User profile operations
- `CommentsService` - Comment CRUD operations

Service locator defined in `lib/utils/locator.dart`.

### Layer Structure

```sh
UI (Screens) → Widgets (FlipCard, CommentsWidget) → Services → Firebase
```

### State Management

- Local state: StatefulWidget with setState()
- Global state: Service Locator pattern
- Reactive streams: RxDart BehaviorSubject in AuthService
- Real-time data: Firestore snapshots
- Persistence: SharedPreferences for onboarding flag

### Firestore Collections

| Collection | Purpose |
| ----------- | --------- |
| `profiles` | User display names (doc ID = userId) |
| `preferences` | User's liked/disliked arrays (doc ID = userId) |
| `image-docs` | Image metadata and stats (doc ID = imageId) |
| `doc-id-lists` | All image IDs for discovery feed |
| `comments` | User comments on images |

## Key Files to Understand

1. `lib/main.dart` - Entry point, routing, service initialization
2. `lib/auth/auth_service.dart` - Auth patterns and state management
3. `lib/home_screen.dart` - Main swipe UI, batch loading logic
4. `functions/src/index.ts` - Cloud Functions (account deletion, web detection)
5. `CLASS_DIAGRAM.md` - Architecture diagram
6. `SEQUENCE_DIAGRAM.md` - Data flow diagrams

## Important Implementation Details

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/ci.yml`):

1. **test** - Runs on all pushes/PRs: format check, analyze, test
2. **claude-code-review** - Runs on PRs only: AI code review
3. **build-android** - Main branch only: builds and deploys to Play Store
4. **build-ios** - Main branch only: builds and deploys to App Store

Build numbers are auto-incremented using `github.run_number`.

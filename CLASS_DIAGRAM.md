# TindArt Class Diagram

## Overview

This diagram shows the class structure and relationships in the TindArt application, a Flutter/Dart mobile app for discovering and rating artwork through a Tinder-like swiping interface.

```mermaid
classDiagram
    %% Models
    class Comment {
        +String userName
        +String commentText
        +Timestamp? timestamp
    }

    %% Services
    class AuthService {
        -FirebaseAuth _auth
        -FirebaseFirestore _firestore
        -BehaviorSubject _profileDocSubject
        +String? currentUserId
        +Future signInWithGoogle()
        +Future signInWithApple()
        +Future signOut()
        +Future deleteAccount()
        +Future~bool~ userHasOnboarded()
        +Stream~DocumentSnapshot~ profileDocStream
    }

    class UsersService {
        -FirebaseAuth _auth
        -FirebaseFirestore _firestore
        +Future~int~ retrieveViewedImages(String userId)
        +Future~String?~ getUserName(String userId)
    }

    class CommentsService {
        -FirebaseAuth _auth
        -FirebaseFirestore _firestore
        +Future addComment(String commentText, String userName, String imageId)
        +Stream~QuerySnapshot~ getComments()
    }

    class Locator {
        -Map~Type, dynamic~ _services
        +void add~T~(T service)
        +T get~T~()
        +bool has~T~()
    }

    %% Screens
    class SignInScreen {
        +State createState()
    }

    class OnboardingScreen {
        +State createState()
    }

    class PrivacyPolicyScreen {
        +Widget build()
    }

    class HomeScreen {
        -List~String~ _imageIds
        -List~String?~ _imageUrls
        -CardSwiperController _controller
        +Future _getImageIds()
        +Future _addImageUrl(String imageId)
        +void _handleSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction)
        +Widget build()
    }

    class ProfileScreen {
        -TextEditingController _nameController
        -int _viewedImagesCount
        +Future _loadProfileData()
        +Future _saveProfile()
        +Widget build()
    }

    %% Widgets
    class FlipCard {
        +Widget front
        +Widget back
        +State createState()
    }

    class CardBack {
        +String imageId
        +String imageUrl
        +Future _deleteAccount()
        +Widget build()
    }

    class CommentsWidget {
        +String imageId
        -TextEditingController _commentController
        +Future _postComment()
        +String _formatTimeAgo(Timestamp timestamp)
        +Widget build()
    }

    %% Main App
    class MyApp {
        +Widget build()
        +GoRouter _router()
    }

    %% Relationships - Service Dependencies
    SignInScreen ..> AuthService : uses
    OnboardingScreen ..> AuthService : uses
    HomeScreen ..> AuthService : uses
    ProfileScreen ..> AuthService : uses
    ProfileScreen ..> UsersService : uses
    CardBack ..> AuthService : uses
    CommentsWidget ..> AuthService : uses
    CommentsWidget ..> UsersService : uses
    CommentsWidget ..> CommentsService : uses

    %% Relationships - Component Composition
    MyApp --> SignInScreen : routes to
    MyApp --> OnboardingScreen : routes to
    MyApp --> PrivacyPolicyScreen : routes to
    MyApp --> HomeScreen : routes to
    MyApp --> ProfileScreen : routes to

    HomeScreen *-- FlipCard : contains
    FlipCard *-- CardBack : back widget
    CardBack *-- CommentsWidget : contains

    %% Service Locator Pattern
    MyApp --> Locator : registers services
    AuthService <.. Locator : manages
    UsersService <.. Locator : manages
    CommentsService <.. Locator : manages

    %% Model Usage
    CommentsWidget ..> Comment : creates
    CommentsService ..> Comment : returns

    %% Firebase Dependencies
    class FirebaseAuth {
        <<external>>
    }
    class FirebaseFirestore {
        <<external>>
    }
    class FirebaseStorage {
        <<external>>
    }

    AuthService --> FirebaseAuth : uses
    AuthService --> FirebaseFirestore : uses
    UsersService --> FirebaseAuth : uses
    UsersService --> FirebaseFirestore : uses
    CommentsService --> FirebaseAuth : uses
    CommentsService --> FirebaseFirestore : uses
    HomeScreen --> FirebaseFirestore : uses
    HomeScreen --> FirebaseStorage : uses
```

## Architecture Patterns

### Service Locator Pattern

The app uses a custom `Locator` class for dependency injection:

- Services are registered in `main.dart`
- Accessed globally via `locate<T>()` function
- Provides type-safe service retrieval

### Layer Architecture

```sh

┌─────────────────────────────────────┐
│         UI Layer (Screens)          │
│  SignInScreen, HomeScreen, etc.     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Widget Layer (Components)      │
│   FlipCard, CardBack, CommentsWidget│
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        Service Layer                │
│ AuthService, UsersService,          │
│ CommentsService                     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Firebase Backend               │
│  Auth, Firestore, Storage           │
└─────────────────────────────────────┘
```

## Key Data Flows

### Authentication Flow

```sh
SignInScreen → AuthService → Firebase Auth → main.dart Router
                                              ├─→ OnboardingScreen (first time)
                                              └─→ HomeScreen (returning user)
```

### Swipe & Comment Flow

```sh
HomeScreen → FlipCard (double-tap) → CardBack → CommentsWidget
                                                      ├─→ UsersService (get username)
                                                      └─→ CommentsService (add/stream comments)
                                                            └─→ Firestore (real-time updates)
```

### Profile Management Flow

```sh
ProfileScreen ─→ UsersService ─→ Firestore (read/write profile)
              └─→ AuthService ─→ Firestore (get user data)
```

## Firestore Collections

| Collection | Document ID | Purpose |
|------------|-------------|---------|
| `profiles` | userId | User profile data (name) |
| `preferences` | userId | User swipe history (liked/disliked image IDs) |
| `image-docs` | imageId | Image metadata and statistics |
| `doc-id-lists` | various | Randomized image ID lists for discovery |
| `comments` | auto-generated | User comments on images |

## State Management

- **Local State**: StatefulWidget with setState
- **Global State**: Service Locator pattern
- **Reactive Streams**:
  - RxDart BehaviorSubject in AuthService
  - Firestore snapshots for real-time data
- **Persistence**: SharedPreferences for onboarding flag

## Key Technologies

- Flutter/Dart framework
- Firebase (Auth, Firestore, Storage, Functions, Analytics, Crashlytics)
- GoRouter for navigation
- RxDart for reactive programming
- flutter_card_swiper for swipe UI

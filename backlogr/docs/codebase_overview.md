# BackLogr Codebase Overview

This document provides a comprehensive overview of the BackLogr application's architecture and codebase structure. BackLogr is a cross-platform, local-first media tracking application built with Flutter, Supabase, and PowerSync.

## Directory Structure (`lib/`)

The application follows a feature-layered architecture separated into core responsibilities:

### 1. `main.dart`
The entry point of the application. It is responsible for:
- Initializing the `flutter_dotenv` package to load API keys securely.
- Initializing the `Supabase` client.
- Setting up the local SQLite database via `PowerSyncDatabase`.
- Connecting PowerSync to the Supabase backend using the `SupabaseConnector`.
- Defining the `AuthWrapper` which listens to Supabase authentication state changes and dynamically routes the user to the `HomeScreen` or `AuthScreen`.

### 2. `database/`
Contains the core configuration for offline-first data syncing.
- **`schema.dart`**: Defines the local SQLite schema for PowerSync. This explicitly maps out tables like `profiles`, `media_items`, `user_lists`, `list_entries`, and `media_journals` so PowerSync knows how to structure the local database and what metadata to sync.
- **`supabase_connector.dart`**: Implements the `PowerSyncBackendConnector`. It handles authenticating with the Supabase backend, fetching credentials, and executing the raw data uploads when network connectivity is present.

### 3. `models/`
Contains the Dart data classes used to parse and manage data throughout the app.
- **`media_item.dart`**: Represents a piece of media (Movie, Game, Book) with properties like `title`, `type`, `externalId`, `posterUrl`, and `releaseDate`.
- **`user_list.dart`**: Represents a custom list created by a user (e.g., "Backlog", "Currently Playing").
- **`list_entry.dart`**: The join-table model that links a `UserList` with a `MediaItem`, storing progress, score, and the user's specific status for that item.

### 4. `repositories/`
Abstracts direct database interactions away from the UI.
- **`media_repository.dart`**: The core repository interacting with `PowerSyncDatabase`. It provides:
  - Reactive streams (`watchUserLists`, `watchListEntries`) that automatically rebuild the UI when local data changes.
  - CRUD operations (`createList`, `addMediaToList`, `updateListEntry`, `removeMediaFromList`).
  - *Note:* Because PowerSync exposes its local tables as SQLite views, `addMediaToList` uses a custom `SELECT` -> `INSERT`/`UPDATE` fallback instead of a traditional SQL `UPSERT`.

### 5. `services/`
Handles external HTTP requests.
- **`api_service.dart`**: Utilizes the `dio` package to query third-party discovery APIs (TMDB, IGDB, AniList, etc.). Currently implemented as a stub returning mock data to demonstrate the media discovery flow.

### 6. `screens/`
Contains all the Flutter UI views.
- **`auth_screen.dart`**: Provides the login and sign-up interfaces using Supabase email/password authentication.
- **`home_screen.dart`**: The main dashboard. Displays the user's custom lists and includes a floating action button to create new lists.
- **`list_detail_screen.dart`**: Displays the `list_entries` for a specific list by subscribing to a joined SQL stream. Includes options to mark items as completed, remove them, or add new media.
- **`add_media_screen.dart`**: The discovery interface. Users can search for media via the `ApiService` and instantly add results directly to their selected list.

## Data Flow (Offline-First Architecture)

1. **Reads**: The UI (e.g., `HomeScreen`) subscribes to streams provided by `MediaRepository`. These streams query the local SQLite database using PowerSync's `db.watch()`. The UI updates instantly (latency < 50ms).
2. **Writes**: When a user adds media or creates a list, the repository executes a local `INSERT`/`UPDATE` on the SQLite database.
3. **Sync**: In the background, `PowerSync` tracks these local mutations and pushes them to Supabase when the device is online. Conversely, it continuously pulls remote changes down to the local SQLite database.

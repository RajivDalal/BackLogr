## 1. Product Overview

**Product Name:** BackLogr

**Description:** A cross-platform, local-first media tracking application that allows users to discover, organize, and journal about movies, TV shows, anime, manga, video games, books, and comics. The app operates offline via a local SQLite database, syncs silently to a cloud PostgreSQL backend, and bridges mobile media consumption with desktop knowledge management by natively exporting journal entries directly to a local Obsidian vault.

**Target Platforms:** Android (Native binary) and Linux Desktop (Arch Linux, Fedora via native GTK).

## 2. Architecture & Tech Stack

- **Frontend:** Flutter (Dart)
    
- **Cloud Database & Auth:** Supabase (PostgreSQL, Row Level Security enabled)
    
- **Local Database:** Embedded SQLite (`sqlite3_flutter_libs`)
    
- **Sync Engine:** PowerSync (Bi-directional background syncing)
    
- **API Client:** Dio (For fetching third-party discovery feeds)
    
- **Data Models:** Inspired by Yamtrack (relational structure linking Users ↔ Lists ↔ Media Items).
    

## 3. Core Features & Functional Requirements

### 3.1. User Authentication & Profile

- **Requirement:** Users must be able to create an account and log in securely.
    
- **Implementation:** Supabase Auth (Email/Password for v1; OAuth extensible).
    
- **Data Isolation:** Row Level Security (RLS) ensures users only download and modify their own tracking lists and journals.
    

### 3.2. Universal Media Tracking (The "Listy" Experience)

- **Requirement:** Users can track disparate media types within unified or segregated lists.
    
- **Data Model:**
    
    - Master `media_items` table (prevents duplicate metadata).
        
    - `user_lists` (e.g., "Backlog", "Currently Playing", "Dropped").
        
    - `list_entries` linking user, list, and media with progress tracking (e.g., Episode 4/12, Page 120, 45 Hours).
        
- **Actions:** Users can create different lists of different media types (movies, shows, books, games and other) For each list they can add, move, rate, and remove media. The app would take the metadata from the respective public APIs listed below. 
    

### 3.3. "Feed of Newest" (Discovery)

- **Requirement:** An explore tab showing new and trending media.
    
- **Implementation:** Client-side HTTP requests using Dio to public APIs.
    
- **Data Sources:**
    
    - Movies/TV: TMDB API
        
    - Anime/Manga: AniList API (GraphQL) / MyAnimeList
        
    - Video Games: IGDB API
        
    - Books: Google Books API / OpenLibrary
        
- **Constraint:** Data from these APIs is ephemeral and only written to the local/cloud database if a user explicitly adds the item to a personal list.
    

### 3.4. Offline-First Synchronization

- **Requirement:** The app must function identically with or without an internet connection.
    
- **Implementation:**
    
    - All UI reads/writes are executed instantly against the local SQLite database.
        
    - PowerSync automatically captures local mutations and streams them to Supabase when network connectivity is restored, handling conflict resolution mathematically.
        

### 3.5. Completion Trigger & Q&A Journal

- **Requirement:** Capturing structured thoughts upon finishing media.
    
- **Trigger:** When a `list_entry` status is updated to "Completed", a Q&A modal is presented to the user.
    
- **Form Data:** Captures customized fields (e.g., rating, review text, favorite character, pros/cons).
    
- **Storage:** Saved to the `media_journals` table with a flag `is_exported_to_obsidian = false`.
    

### 3.6. The Obsidian Desktop Bridge (Linux Exclusive)

- **Requirement:** Silently generate Markdown files in the user's local Obsidian Vault.
    
- **Implementation:**
    
    - The Linux desktop app allows the user to select their local Obsidian Vault directory path.
        
    - On startup/background tick, the desktop app queries SQLite for journals where `is_exported_to_obsidian = false`.
        
    - App uses `dart:io` to generate a `.md` file formatted with YAML frontmatter (Obsidian properties) based on the Q&A data.
        
    - App saves the file to the Vault and updates the database flag to `true`.
        

## 4. Non-Functional Requirements

- **Performance:** UI interactions (adding to a list, rating) must reflect instantly (<50ms) regardless of network state, utilizing the local database.
    
- **Cross-Platform Parity:** The UI must be responsive, utilizing desktop screen real-estate for grids and sidebars on Linux, while using bottom navigation and standard lists on Android.
    
- **Security:** Database credentials and API keys must be hidden via `.env` files and omitted from version control.
    

## 5. Out of Scope (For v1)

- iOS and Windows/macOS desktop builds.
    
- Social features (following other users, sharing lists publicly).
    
- Self-hosting the cloud backend (relying on Supabase BaaS for v1).
    
- Direct API integration with Plex/Jellyfin for automatic watch tracking.
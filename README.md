# Salah Buddy (starter scaffold)

A Flutter starter matching the surah-list + audio-player UI you're aiming for.

## Setup

```bash
flutter create --project-name quran_app .    # if starting fresh, run this first
flutter pub get
flutter run
```

## What's included
- `lib/models/surah.dart` — data model for a surah
- `lib/services/quran_api_service.dart` — fetches surah list + audio URLs from the free alquran.cloud API
- `lib/services/audio_player_service.dart` — app-wide audio player (play/pause/skip), built on `just_audio`
- `lib/screens/surah_list_screen.dart` — the dark-themed list screen with search/timer/settings icons
- `lib/widgets/mini_player.dart` — bottom mini-player bar
- `lib/main.dart` — app entry point, wires up Provider + dark theme

## Next steps to fill in
1. **Reciter selection** — currently hardcoded to `ar.alafasy` (Mishary Alafasy) in `QuranApiService.audioUrlFor`. Add a picker and store the choice in `shared_preferences`.
2. **Background audio** — wire up `audio_service` so playback survives app backgrounding and shows lock-screen controls (currently only `just_audio` is used directly).
3. **Prayer times** — the `adhan` package is in `pubspec.yaml` but not yet used; add a screen that calculates times from the user's location.
4. **Offline mode** — bundle `assets/data/surahs.json` as a fallback so the list loads without network, and cache downloaded audio files locally.
5. **Search screen** — the search icon in the app bar is currently a no-op.
6. **Durations** — the API doesn't return per-surah audio duration; you'll need to either hardcode it, calculate it after first playback, or use `just_audio`'s `durationStream` once a track loads.

## Why these libraries
- `just_audio` — handles streaming + local audio playback reliably, widely used
- `provider` — simplest state management for something this size; swap for Riverpod/Bloc if the app grows
- `sqflite` — for bookmarks/favorites/last-played position once you add persistence
- `adhan` — pure-Dart prayer time calculations (no API call needed)

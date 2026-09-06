# RA9MANA DZ Android

A real Flutter Android app for the RA9MANA legal library. References are stored in SQLite and remain available offline. When the app starts or the user taps Sync, it fetches published references from the Flask API and updates the local database. PDFs are downloaded on first opening and then remain available offline.

## Important
Set `apiBase` and `publicBase` in `lib/main.dart` to the final API and website base URLs before release.

The Flask server must expose:
`GET /api/references` returning either a JSON array or `{ "references": [...] }`.

## Build APK locally
```bash
flutter pub get
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`


## How synchronization works
- The app always opens from the local SQLite database, so the library remains usable without internet.
- At startup it tries `GET /api/references`.
- Only records with `status=published` are stored locally. Existing records are replaced by ID, so newly published references appear automatically after the next successful sync.
- A PDF is downloaded only when the user opens it the first time; the downloaded file is then kept on the device for offline reading.

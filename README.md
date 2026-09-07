# RA9MANA DZ — Android Legal Library

Standalone Flutter Android application for the RA9MANA DZ legal reference library.

## Features
- Legal references stored locally in SQLite.
- Automatic synchronization when the device has internet access.
- References remain available offline after synchronization.
- PDF files are downloaded once and cached locally for offline reading.
- Search and reference details.
- External source links open in the browser.
- No WebView: this is a real Flutter Android application.

## Build with GitHub Actions
1. Create a GitHub repository.
2. Upload the contents of this folder to the repository root.
3. Push to `main`, or run **Actions → Build RA9MANA APK → Run workflow**.
4. Open the completed workflow run.
5. Download the artifact named `ra9mana-dz-apk`.

The workflow uses Flutter 3.47.2 and `pdfrx 2.6.1`, which supports Flutter 3.47/Dart 3.13+.

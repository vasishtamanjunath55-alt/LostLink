# LostLink

Flutter campus lost-and-found app. Backend: Supabase (free). APK built by GitHub Actions (free).
No Flutter install needed. See SETUP steps in the chat, summarised here:

1. Supabase: new project -> SQL Editor -> run `supabase_setup.sql`.
   Authentication -> Providers -> Email -> turn OFF "Confirm email" (easiest for a campus pilot).
2. Put your Project URL + anon key in `lib/config.dart`.
3. Push this folder to a GitHub repo (branch `main`). The "Build LostLink APK" action runs automatically.
4. Open the repo -> Releases -> download `LostLink.apk` on your phone -> install (allow "unknown sources").

Local build (optional): install Flutter, run
`flutter create . --platforms=android`, add INTERNET permission to AndroidManifest.xml, then `flutter build apk --release`.

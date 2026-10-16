# LostLink

Flutter campus lost-and-found app. Backend: Supabase (free). APK built by GitHub Actions (free).

## Setup
1. Supabase: new project -> SQL Editor -> run `supabase_setup.sql`.
   Authentication -> Sign In / Providers -> Email -> turn OFF "Confirm email".
2. Put your Project URL + anon key in `lib/config.dart`.
3. Push everything (including `.github`, `assets`, `lib`, `pubspec.yaml`) to a GitHub repo, branch `main`.
   The "Build LostLink APK" action runs automatically (~8 min).
4. Repo -> Releases -> download `LostLink.apk` on your phone -> install.

## Customising
- Colours: `lib/theme.dart` (`AppColors.brand`, `brandAlt`) and the two `#4F46E5` values in `pubspec.yaml`.
- App icon: replace `assets/icon/icon.png` and `icon_foreground.png`.
- College email only: `allowedEmailDomain` in `lib/config.dart`.
- Dark mode follows the phone's setting.

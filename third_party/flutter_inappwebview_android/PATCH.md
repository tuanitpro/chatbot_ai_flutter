# AGP 9 compatibility patch

Source: flutter_inappwebview_android 1.1.3 from pub.dev. The upstream Apache-2.0
license is retained in LICENSE.

Only the two ProGuard defaults in android/build.gradle are changed from
proguard-android.txt to proguard-android-optimize.txt, as required by AGP 9.
Dart and native runtime code are unchanged. The root pubspec.yaml selects this
copy using dependency_overrides.

When a compatible stable upstream package is available, remove the override
and this directory after verifying Android builds.

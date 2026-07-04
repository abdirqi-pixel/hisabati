@echo off
echo تنظيف المشروع...
flutter clean

echo تحميل الحزم...
flutter pub get

echo فحص المشروع...
flutter analyze

echo بناء APK release...
flutter build apk --release

echo بناء AAB release...
flutter build appbundle --release

echo تم الانتهاء.
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo AAB: build\app\outputs\bundle\release\app-release.aab
pause

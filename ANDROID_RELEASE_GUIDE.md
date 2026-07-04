# دليل بناء نسخة Android Release لتطبيق حساباتي

## المتطلبات
- تثبيت Flutter SDK.
- تثبيت Android Studio.
- تثبيت Android SDK.
- تشغيل الأمر:
```bash
flutter doctor
```

## بناء نسخة APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```

المسار الناتج:
```text
build/app/outputs/flutter-apk/app-release.apk
```

## بناء نسخة AAB للنشر في Google Play
```bash
flutter build appbundle --release
```

المسار الناتج:
```text
build/app/outputs/bundle/release/app-release.aab
```

## سكربت جاهز
على macOS/Linux:
```bash
bash scripts/build_android_release.sh
```

على Windows:
```bat
scripts\build_android_release.bat
```

## ملاحظات مهمة قبل Google Play
- تغيير اسم الحزمة Package Name.
- إضافة أيقونة نهائية.
- إضافة شاشة Splash نهائية.
- إنشاء keystore خاص للنشر.
- عدم مشاركة ملف keystore أو كلمة مروره مع أي شخص.
# دليل تجهيز نسخة iOS لتطبيق حساباتي

## المتطلبات
- جهاز macOS.
- Xcode.
- حساب Apple Developer.
- Flutter SDK.

## أوامر أولية
```bash
flutter clean
flutter pub get
flutter build ios --release
```

## النشر
- افتح مجلد ios داخل Xcode.
- حدّث Bundle Identifier.
- اختر Team من حساب Apple Developer.
- جهّز Signing & Capabilities.
- أنشئ Archive من Xcode.
- ارفع النسخة عبر App Store Connect.

## ملاحظات
- يجب اختبار صلاحيات الكاميرا والمعرض والبصمة.
- يجب إضافة Privacy Strings داخل Info.plist.
- يجب تجهيز سياسة خصوصية قبل النشر.
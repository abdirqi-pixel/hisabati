# إصلاحات Flutter الشائعة

## مشكلة تعارض الحزم
جرّب:
```bash
flutter clean
flutter pub get
```

## مشكلة import غير مستخدم
احذف الاستيراد غير المستخدم من الملف.

## مشكلة كلاس غير موجود
تحقق من:
- اسم الملف.
- مسار import.
- اسم الكلاس داخل الملف.

## مشكلة route غير معروف
راجع:
```text
lib/core/router/app_router.dart
```

## مشكلة قاعدة بيانات
راجع:
```text
lib/core/database/app_database.dart
```

## مشكلة Android build
جرّب:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## مشكلة iOS
جرّب:
```bash
cd ios
pod install
cd ..
flutter build ios --release
```
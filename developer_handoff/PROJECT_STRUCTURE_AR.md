# شرح بنية مشروع حساباتي

## أهم المجلدات
- `lib/`: كود التطبيق الأساسي.
- `lib/core/`: الخدمات العامة، قاعدة البيانات، الراوتر، الأدوات.
- `lib/features/`: شاشات ومزايا التطبيق.
- `assets/`: ملفات الصور والخطوط والموارد.
- `scripts/`: سكربتات البناء.
- `branding/`: الهوية البصرية.
- `store_listing/`: ملفات وصف المتجر.
- `field_testing/`: ملفات الاختبار الميداني.

## أهم الملفات
- `pubspec.yaml`: الحزم والإعدادات.
- `lib/main.dart`: نقطة بداية التطبيق.
- `lib/core/router/app_router.dart`: مسارات التنقل.
- `lib/core/database/app_database.dart`: قاعدة البيانات والجداول.
- `README.md`: ملخص مراحل المشروع.
- `ANDROID_RELEASE_GUIDE.md`: دليل بناء Android.
- `IOS_RELEASE_GUIDE.md`: دليل تجهيز iOS.

## أين يبدأ المطور؟
1. تشغيل `flutter pub get`.
2. مراجعة `pubspec.yaml`.
3. فتح `lib/main.dart`.
4. فحص `app_router.dart`.
5. فحص `app_database.dart`.
6. تشغيل التطبيق على جهاز حقيقي.
7. إصلاح أخطاء البناء والـ runtime.
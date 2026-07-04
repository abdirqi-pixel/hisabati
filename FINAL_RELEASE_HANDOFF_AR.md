# تسليم الإصدار النهائي - حساباتي v1.0

## حالة المشروع
المشروع جاهز كحزمة Release Candidate من ناحية الهيكل والملفات والوثائق. قبل النشر يجب تشغيله وبناؤه على جهاز مطور يحتوي Flutter وAndroid Studio/Xcode.

## خطوات التسليم للمطور
1. فك ضغط ملف المشروع.
2. فتح المجلد في VS Code أو Android Studio.
3. تشغيل:
```bash
flutter pub get
flutter analyze
flutter run
```
4. إصلاح أي خطأ يظهر أثناء التشغيل.
5. اختبار الوظائف الأساسية.
6. بناء نسخة Android:
```bash
flutter build apk --release
flutter build appbundle --release
```
7. تجهيز نسخة iOS من Xcode.

## ملفات مهمة داخل المشروع
- README.md
- ANDROID_RELEASE_GUIDE.md
- IOS_RELEASE_GUIDE.md
- PRIVACY_POLICY_AR.md
- STORE_ASSETS_CHECKLIST.md
- QA_TEST_CASES_v1.0.md
- STABILIZATION_PLAN_v1.0_RC.md
- RELEASE_NOTES_v1.0_BETA.md
- RELEASE_CONFIG_v1.0_RC.json
- branding/
- store_listing/
- scripts/

## ملاحظات النشر
- لا تشارك keystore أو كلمة المرور.
- أضف رابط سياسة الخصوصية قبل رفع التطبيق.
- اختبر التطبيق على جهاز حقيقي.
- جهز صور المتجر والأيقونة النهائية.
# ملاحظات إعداد Android و iOS

## البصمة و Face ID
تمت إضافة حزمة `local_auth`.

### Android
قد تحتاج إضافة صلاحية في AndroidManifest.xml حسب نسخة Flutter/Android:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### iOS
أضف داخل Info.plist:

```xml
<key>NSFaceIDUsageDescription</key>
<string>يستخدم حساباتي Face ID لفتح التطبيق بأمان.</string>
```

## التنبيهات
تمت إضافة `flutter_local_notifications`.
على Android 13+ يحتاج التطبيق صلاحية الإشعارات.

## OCR / Google ML Kit
تمت إضافة `google_mlkit_text_recognition`.

### Android
تأكد من أن minSdkVersion مناسب لحزم ML Kit. يفضل استخدام minSdkVersion 21 أو أعلى.

### iOS
قد تحتاج التأكد من إعدادات الكاميرا والمعرض في Info.plist:
```xml
<key>NSCameraUsageDescription</key>
<string>يستخدم حساباتي الكاميرا لتصوير الفواتير.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>يستخدم حساباتي المعرض لاختيار صور الفواتير.</string>
```


## المزامنة السحابية
تمت إضافة مزامنة اختيارية عبر مجلد يختاره المستخدم.

الفكرة العملية:
- على Android يمكن اختيار مجلد Google Drive إذا كان ظاهرًا عبر مدير الملفات.
- على iOS يمكن اختيار مجلد iCloud Drive إذا كان متاحًا.
- التطبيق ينشئ نسخة hbak مشفرة وينسخها إلى هذا المجلد.
- الاستعادة تتم من نفس المجلد بعد إدخال كلمة المرور.

هذه ليست مزامنة مباشرة عبر API رسمي، لكنها طريقة آمنة وبسيطة وعملية للمستخدمين بدون إعدادات معقدة.

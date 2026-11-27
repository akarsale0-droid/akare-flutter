# تطبيق العقارات — Flutter Android

هذه حزمة Flutter متعددة المنصات، ويحتوي هذا التصدير على ملفات Android وكود التطبيق الحالي بعد دمج آخر التعديلات.

## الميزات الحالية

- تصفح العقارات الحقيقية من Supabase للزائر بدون تسجيل دخول.
- البحث والتصفية حسب بيع أو إيجار.
- صفحة تفاصيل العقار والصور.
- تسجيل الدخول وإنشاء الحساب وتسجيل الخروج.
- الإعجاب والمفضلة وتفاعلات الإيموجي والتعليقات.
- ملفات المستخدمين والتفاعلات والتعليقات المرتبطة بالعقارات.
- صلاحيات الأدمن المعتمدة على `public.is_admin()` وRLS في Supabase.
- لوحة إدارة كاملة لإضافة العقارات وتعديلها وحذفها.
- تعديل السعر والوصف ونوع العرض والصور.
- رفع الصور الجديدة إلى Supabase Storage.
- حذف الصور التي أزيلت من التعديل أو حذفها عند حذف العقار.
- تغيير حالة العقار إلى مباع/مؤجر.

## تشغيل Android

من مجلد المشروع:

```bash
flutter pub get
flutter run -d android \\
  --dart-define=SUPABASE_URL=https://akzpiodzpkerdnccwlhw.supabase.co \\
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

استبدل `YOUR_SUPABASE_ANON_KEY` بمفتاح النشر العام لديك. لا تضع المفتاح داخل ملفات المصدر أو Git.

## بناء APK Release

```bash
flutter build apk --release \\
  --dart-define=SUPABASE_URL=https://akzpiodzpkerdnccwlhw.supabase.co \\
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

ينتج الملف عادةً في:

```text
build/app/outputs/flutter-apk/release/app-release.apk
```

## ملاحظات مهمة

- يجب تطبيق `schema.sql` وسياسات RLS وStorage في مشروع Supabase قبل استخدام وظائف الأدمن.
- المستخدم العادي يستطيع التصفح والتفاعل وفق سياسات قاعدة البيانات، بينما عمليات إضافة وتعديل وحذف العقارات مقيدة بالأدمن.
- تم تمرير قيم Supabase عبر `--dart-define`، ولا تُحفظ في المصدر.
- تم التحقق من المشروع بنجاح عبر `flutter analyze` و`flutter test`.
- بناء APK في بيئة ARM64 قد يتوقف بسبب عدم توافق أداة Android `aapt2`؛ استخدم Windows أو Linux x86_64 أو CI متوافقًا عند البناء.

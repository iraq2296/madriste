# دليل النشر والتشغيل الإنتاجي لمنصة مَدرَستي (MADRASI)

يوثق هذا الدليل كافة خطوات نقل وتجهيز منصة **مَدرَستي** إلى بيئة الإنتاج السحابية (Production) ومتاجر التطبيقات (Google Play Store و Apple App Store).

---

## 1. إعداد ونشر خادم وقاعدة بيانات Supabase

### أ. إنشاء المشروع وتطبيق المخطط:
1. أنشئ مشروعاً جديداً على [Supabase Console](https://supabase.com).
2. افتح **SQL Editor** ونفّذ ملف المخطط الأساسي:
   ```text
   supabase/migrations/001_initial_schema.sql
   ```
   *سيقوم هذا الملف بإنشاء الـ 28 جدولاً وتفعيل حماية RLS و Triggers الخاصة بحفظ حد الجهازين وشارة التوثيق.*
3. (اختياري) قم بتنفيذ ملف البذور والبيانات العراقية الأولية:
   ```text
   supabase/seed.sql
   ```

### ب. استخراج مفاتيح الربط وضبط البيئة:
- من **Project Settings -> API**، انسخ:
  - `Project URL`
  - `anon / public key`
- أنشئ ملف `.env` داخل مجلد `app/` مستنداً إلى `.env.example`:
  ```env
  MADRASI_ENV=production
  SUPABASE_URL=https://your-project.supabase.co
  SUPABASE_ANON_KEY=eyJhbGciOi...
  AGORA_APP_ID=your_agora_app_id
  ```

### ج. نشر دوال الحافة (Edge Functions):
لتشغيل خدمة مطابقة الوجه الآلية بدون خوادم خارجية:
```bash
supabase functions deploy verify-face --project-ref your-project-id
```

---

## 2. إعداد خدمات الطرف الثالث (Third-Party Services)

### أ. مكالمات الصوت والفيديو الفورية (Agora RTC):
1. سجّل حساباً في [Agora Console](https://console.agora.io).
2. أنشئ مشروعاً جديداً واختر نمط الأمان **Testing Mode** أو **Token Mode**.
3. ضع `App ID` و `App Certificate` في إعدادات البيئة.

### ب. الإشعارات الفورية (Firebase Cloud Messaging - FCM):
1. أنشئ مشروعاً في [Firebase Console](https://console.firebase.google.com).
2. أضف تطبيق Android باستخدام الـ Package Name:
   `iq.madrasi.madrasi`
   وقم بتنزيل ملف `google-services.json` إلى `app/android/app/`.
3. أضف تطبيق iOS وحمّل ملف `GoogleService-Info.plist` إلى `app/ios/Runner/`.
4. ارفع مفتاح **Apple Push Notification Service (APNs Key)** بصيغة `.p8` داخل لوحة تحكم Firebase تحت قسم إعدادات Cloud Messaging.

### ج. بوابات الدفع الوطنية (Mastercard فقط):
- راجع ملف [PAYMENTS.md](file:///c:/Users/walid/OneDrive/Desktop/مدرستي/docs/PAYMENTS.md) للحصول على معايير الدمج مع بوابة دفع ماستركارد المعتمدة في العراق.

---

## 3. نشر وتجهيز تطبيق Android (Google Play Store)

### أ. توليد مفتاح التوقيع (Upload Keystore):
```powershell
keytool -genkey -v -keystore app/android/madrasi-release.keystore -alias madrasi -keyalg RSA -keysize 2048 -validity 10000
```

### ب. بناء حزمة التطبيق الرسمية (AAB):
```powershell
cd app
flutter build appbundle --release
```
*الحزمة الناتجة ستكون في المسار:*
`app/build/app/outputs/bundle/release/app-release.aab`

---

## 4. نشر وتجهيز تطبيق iOS (Apple App Store)

### أ. متطلبات البناء:
- جهاز كمبيوتر يعمل بنظام macOS ومثبت عليه برنامج Xcode.
- تثبيت CocoaPods: `sudo gem install cocoapods`.

### ب. خطوات التجميع والتوقيع:
```bash
cd app
flutter build ipa --release
```
*أو فتح مجلد `app/ios` عبر Xcode واختيار **Product -> Archive** ثم رفع التطبيق مباشرة إلى App Store Connect.*

---

## 5. اختبارات التكامل الآلي (CI/CD)

تم ضبط مسار الـ Pipeline تلقائياً في [.github/workflows/ci.yml](file:///c:/Users/walid/OneDrive/Desktop/مدرستي/.github/workflows/ci.yml).
بمجرد ربط المستودع بـ GitHub، ستقوم المنصة آلياً بما يلي:
1. تشغيل فحص الجودة `dart analyze lib`.
2. تنفيذ حزمة اختبارات القواعد الصارمة `flutter test`.
3. بناء حزم التوزيع للأندرويد والويب.

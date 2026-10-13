# دليل اختبار الإصدار 0.0.6 — التمام اليومي

## الاختبار الإلزامي: Windows

1. فك ضغط `Altamam_AlYawmi_Part_VI_GitHub_Source.zip` وارفع **محتوياته** إلى جذر المستودع الخاص `Win-manger` على الفرع `main`، مع مجلد `.github` المخفي.
2. افتح GitHub → Actions → `Windows foundation build`.
3. انتظر نجاح التحقق من SQLite، اختبارات البنية، `flutter analyze`، `flutter test`، ثم `flutter build windows --release`.
4. راقب `Show dependency cache status`، إذ تعيد خطوات GitHub استخدام Flutter SDK وDart Pub عند توفر كاش مطابق.
5. حمّل `Altamam_AlYawmi_Part_VI_Windows_x64` من قسم Artifacts. يحتوي ملف ZIP الداخلي على `التمام اليومي.exe` مع ملفات DLL ومجلد `data`.
6. لا يتطلب اختبار البناء امتلاك كمبيوتر Windows؛ لكن التحقق من تشغيل واجهة Windows محليًا سيظل **غير مثبت** حتى التجربة على Windows أو بيئة توافقية ناجحة.
7. عند فشل خطوة أرسل نص الخطأ الكامل، ولا تنتقل إلى الجزء السابع قبل إصلاحه.

## خيار إضافي مخصص لهاتف Android (اختياري)

1. افتح Actions ثم اختر `Android visual preview (optional)`.
2. اضغط `Run workflow` يدويًا وانتظر النتيجة.
3. افتح Artifacts وحمّل `Altamam_AlYawmi_Part_VI_Android_ReadOnly_Preview`.
4. فك الضغط على هاتف أندرويد، وستجد `app-debug.apk` لتثبيته بعد السماح بالتثبيت من مصدر موثوق في إعدادات الجهاز.
5. تطبيق Android المعروض **معاينة للواجهة غير التشغيلية فقط**. ليس نسخة Windows، ولا يحوي قاعدة بيانات إنتاجية أو تسجيل دخول فعليًا، ولا يستخدم مع بيانات حساسة.

**نقطة التوقف:** يجب إرسال نتيجة البناء الإلزامي على GitHub قبل تنفيذ الجزء التالي.

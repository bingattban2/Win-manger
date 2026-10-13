# الجزء الثاني — المصطلحات العربية الثابتة

**اسم البرنامج المعروض في Windows:** التمام اليومي

هذه القائمة **ملزمة** لشاشات البرنامج القادمة. يخزن كل مصطلح مرة واحدة في
`lib/core/config/business_terms.dart` ويستخدم بالمعرف الثابت للـ`BusinessTerm`.
لا ينبغي استخدام النص العربي نفسه كمفتاح قاعدة بيانات، ولا تُشتق منه أسماء الجداول.

| English domain | Dart identifier | Arabic label |
|---|---|---|
| Personnel | `personnel` | الأفراد |
| Personnel number | `personnelNumber` | الرقم (ع) |
| Site | `site` | الموقع |
| Force strength | `forceStrength` | القوة |
| Present | `present` | موجود |
| Leave | `leave` | إجازة |
| Absent | `absent` | غياب |
| Permission | `permission` | إذن |
| Daily preparation | `dailyPreparation` | التحضير |
| Monthly accountability | `monthlyAccountability` | التمام الشهري |
| Internal transfer | `internalTransfer` | النقل الداخلي |
| External transfer | `externalTransfer` | النقل الخارجي |
| Dismissal | `dismissal` | الفصل |
| Dismissed | `dismissed` | مفصول |
| Archive | `archive` | الأرشيف |
| User management | `userManagement` | إدارة المستخدمين |
| General administration | `generalAdministration` | الإدارة العامة |
| Ordinary administration | `ordinaryAdministration` | الإدارة العادية |
| Supervisors | `supervisors` | المشرفين |
| Undefined site | `undefinedSite` | غير محدد |

## قواعد يجب الالتزام بها

- `الرقم (ع)` حرفيًا دون تحريف، وهو معرف أعمال للأفراد وليس رقم صف.
- «التمام اليومي» اسم المنتج؛ «التمام الشهري» اسم شاشة، و«التحضير» عملية داخل البرنامج، ولا يجوز الخلط بينها.
- «غير محدد» اسم الموقع المحمي في قاعدة البيانات مستقبلًا، وليس قيمة فارغة.
- أسماء الحالات الافتراضية ثابتة عند تأسيس النظام؛ في المراحل اللاحقة تكون الحالات كيانات ذات `status_id` ثابت، ويمكن إضافة حالات جديدة وتغيير العرض حسب الصلاحيات دون تغيير هوية السجل.
- الواجهة التأسيسية الحالية تعرض المصطلحات للقراءة فقط؛ لا توجد أزرار تشغيلية وهمية.

## التحقق

- `test/business_terms_test.dart`: فحص المصطلحات العشرين حرفيًا، وعدم التكرار، والاسم الرسمي.
- `test/foundation_screen_test.dart`: التحقق من ظهور المصطلحات على الشاشة التأسيسية.
- `scripts/test_windows_metadata.py`: فحص عنوان Windows وبيانات ملف EXE على مثال قالب Flutter.
- `scripts/patch_windows_metadata.py --check`: فحص الملفات الأصلية المولّدة أثناء GitHub Actions.

## Windows

- اسم مشروع Dart واسم `BINARY_NAME` داخليان: `adwas_personnel` لمنع كسر المسارات.
- عنوان نافذة Windows وحقلا `FileDescription` و`ProductName`: **التمام اليومي**.
- اسم الملف التنفيذي بعد التغليف في ZIP الاختباري: **التمام اليومي.exe**.
- إنشاء اختصار سطح المكتب بواسطة المثبّت لاحقًا، وليس ضمن الإصدار التأسيسي الحالي؛ سيكون اسم الاختصار «التمام اليومي».

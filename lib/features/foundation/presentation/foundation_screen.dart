import 'package:adwas_personnel/core/config/project_info.dart';
import 'package:adwas_personnel/core/config/business_terms.dart';
import 'package:flutter/material.dart';

/// Honest, read-only bootstrap screen; operational modules are NOT mocked.
/// Replaced with real authentication/navigation in the prescribed phases.
class FoundationScreen extends StatelessWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 750),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFFE0E7EF)),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.groups_2_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  ProjectInfo.nameArabic,
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ProjectInfo.codeName,
                                  textDirection: TextDirection.ltr,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFFEAF3FD),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'المرحلة 00 — تأسيس المشروع',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF124A77),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'هذه نسخة أولية لاختبار بناء تطبيق Windows. '
                              'تم إعداد هيكل Flutter وتوحيد المصطلحات العربية، '
                              'ولم تُفعّل الوظائف التشغيلية بعد.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'المصطلحات العربية المعتمدة',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: BusinessTerm.values
                            .map((term) => _ReadOnlyTerm(label: term.arabic))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'نطاق الاختبار الحالي',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const _InfoLine('تشغيل نافذة تطبيق Windows بواجهة عربية.'),
                      const _InfoLine('فحص بناء التطبيق والاختبارات الآلية على GitHub.'),
                      const _InfoLine('تثبيت مواصفات 43 مرحلة هندسية داخل المستودع.'),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'قاعدة البيانات المشفرة، الحسابات والصلاحيات، '
                        'والتحضير والأرشفة ستُنفَّذ في مراحلها التالية '
                        'وتتطلب اختبارات مستقلة قبل الاعتماد.',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'نسخة تأسيسية ${ProjectInfo.version}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.check_circle_outline, size: 19,
            color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

/// Display-only, deliberately not a clickable workflow before its real phase.
class _ReadOnlyTerm extends StatelessWidget {
  const _ReadOnlyTerm({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDCE5EF)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

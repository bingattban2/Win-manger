import 'package:adwas_personnel/app/personnel_app.dart';
import 'package:adwas_personnel/core/config/project_info.dart';
import 'package:adwas_personnel/core/config/business_terms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foundation build is explicitly not production-ready', () {
    expect(ProjectInfo.foundationPhase, 0);
    expect(ProjectInfo.isProductionReady, isFalse);
  });

  testWidgets('foundation screen shows accurate Arabic build status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PersonnelApp());
    expect(find.text(ProjectInfo.nameArabic), findsOneWidget);
    expect(find.text('الجزء الخامس — الحسابات والصلاحيات'), findsOneWidget);
    for (final term in BusinessTerm.values) {
      expect(find.text(term.arabic), findsOneWidget);
    }
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}

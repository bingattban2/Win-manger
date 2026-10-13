import 'package:adwas_personnel/core/config/business_terms.dart';
import 'package:adwas_personnel/core/config/project_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const requiredArabic = <BusinessTerm, String>{
    BusinessTerm.personnel: 'الأفراد',
    BusinessTerm.personnelNumber: 'الرقم (ع)',
    BusinessTerm.site: 'الموقع',
    BusinessTerm.forceStrength: 'القوة',
    BusinessTerm.present: 'موجود',
    BusinessTerm.leave: 'إجازة',
    BusinessTerm.absent: 'غياب',
    BusinessTerm.permission: 'إذن',
    BusinessTerm.dailyPreparation: 'التحضير',
    BusinessTerm.monthlyAccountability: 'التمام الشهري',
    BusinessTerm.internalTransfer: 'النقل الداخلي',
    BusinessTerm.externalTransfer: 'النقل الخارجي',
    BusinessTerm.dismissal: 'الفصل',
    BusinessTerm.dismissed: 'مفصول',
    BusinessTerm.archive: 'الأرشيف',
    BusinessTerm.userManagement: 'إدارة المستخدمين',
    BusinessTerm.generalAdministration: 'الإدارة العامة',
    BusinessTerm.ordinaryAdministration: 'الإدارة العادية',
    BusinessTerm.supervisors: 'المشرفين',
    BusinessTerm.undefinedSite: 'غير محدد',
  };

  test('all Part II labels match exactly, including the personnel number', () {
    expect(requiredArabic.length, 20);
    expect(BusinessTerm.values.length, requiredArabic.length);
    for (final entry in requiredArabic.entries) {
      expect(entry.key.arabic, entry.value);
    }
    expect(
      BusinessTerm.values.map((term) => term.arabic).toSet().length,
      BusinessTerm.values.length,
    );
  });

  test('the user-facing Windows app title is التمام اليومي', () {
    expect(ProjectInfo.nameArabic, 'التمام اليومي');
    expect(ProjectInfo.foundationPhase, 0);
    expect(ProjectInfo.isProductionReady, isFalse);
  });
}

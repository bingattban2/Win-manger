/// Fixed Arabic business vocabulary defined in the project's Part II contract.
///
/// This enum describes *labels*, not database records. Attendance statuses
/// themselves will have stable IDs and configurable names in later phases.
/// Never infer a business identity or database column name from [arabic].
enum BusinessTerm {
  personnel('الأفراد'),
  personnelNumber('الرقم (ع)'),
  site('الموقع'),
  forceStrength('القوة'),
  present('موجود'),
  leave('إجازة'),
  absent('غياب'),
  permission('إذن'),
  dailyPreparation('التحضير'),
  monthlyAccountability('التمام الشهري'),
  internalTransfer('النقل الداخلي'),
  externalTransfer('النقل الخارجي'),
  dismissal('الفصل'),
  dismissed('مفصول'),
  archive('الأرشيف'),
  userManagement('إدارة المستخدمين'),
  generalAdministration('الإدارة العامة'),
  ordinaryAdministration('الإدارة العادية'),
  supervisors('المشرفين'),
  undefinedSite('غير محدد');

  const BusinessTerm(this.arabic);

  final String arabic;
}

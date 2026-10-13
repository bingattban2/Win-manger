import 'package:adwas_personnel/core/security/account_policy.dart';

/// Navigation only mirrors domain authorization; it never replaces it.
class AppNavigationDestination {
  const AppNavigationDestination(this.title, this.permission);

  final String title;
  final AppPermission permission;
}

abstract final class RoleNavigationPolicy {
  static const destinations = <AppNavigationDestination>[
    AppNavigationDestination('الرئيسية', AppPermission.dashboard),
    AppNavigationDestination('التمام الشهري', AppPermission.monthlyAccountability),
    AppNavigationDestination('الأرشيف', AppPermission.archives),
    AppNavigationDestination('التحضير', AppPermission.dailyPreparation),
    AppNavigationDestination('النقل الداخلي', AppPermission.internalTransfer),
    AppNavigationDestination('النقل الخارجي', AppPermission.externalTransfer),
    AppNavigationDestination('الفصل', AppPermission.dismissal),
    AppNavigationDestination('الأفراد', AppPermission.personnelEditing),
    AppNavigationDestination('إدارة المواقع', AppPermission.siteManagement),
    AppNavigationDestination('إدارة الحالات', AppPermission.statusManagement),
    AppNavigationDestination('سجل العمليات', AppPermission.auditViewing),
    AppNavigationDestination('التقارير', AppPermission.reports),
    AppNavigationDestination('إدارة المستخدمين', AppPermission.viewUserManagement),
    AppNavigationDestination('الإعدادات', AppPermission.settings),
  ];

  static List<AppNavigationDestination> visibleFor(AppRole role) => [
    for (final destination in destinations)
      if (AccountPolicy.allows(role, destination.permission)) destination,
  ];
}

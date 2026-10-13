/// Mandatory PART V authorization for all three personnel-administration roles.
/// Screens are derived from this policy; services MUST independently call it.
enum AppRole {
  generalAdmin('GENERAL_ADMIN', 'الإدارة العامة'),
  ordinaryAdmin('ORDINARY_ADMIN', 'الإدارة العادية'),
  supervisor('SUPERVISOR', 'المشرفين');

  const AppRole(this.storageValue, this.arabicName);
  final String storageValue;
  final String arabicName;
}

enum AppPermission {
  dashboard,
  monthlyAccountability,
  archives,
  dailyPreparation,
  internalTransfer,
  externalTransfer,
  dismissal,
  personnelEditing,
  statusManagement,
  siteManagement,
  excelImport,
  excelExport,
  reports,
  auditViewing,
  settings,
  backup,
  restore,
  addOrdinaryAdmin,
  manageOrdinaryAdmin,
  addSupervisor,
  manageSupervisor,
  viewUserManagement,
}

class PermissionDenied implements Exception {
  const PermissionDenied();
  @override
  String toString() => 'Permission denied';
}

abstract final class AccountPolicy {
  static const Set<AppPermission> _management = {
    AppPermission.addOrdinaryAdmin,
    AppPermission.manageOrdinaryAdmin,
    AppPermission.addSupervisor,
    AppPermission.manageSupervisor,
    AppPermission.viewUserManagement,
  };

  static bool allows(AppRole role, AppPermission permission) {
    if (!_management.contains(permission)) return true;
    switch (role) {
      case AppRole.generalAdmin:
        return true;
      case AppRole.ordinaryAdmin:
        return permission == AppPermission.addSupervisor ||
            permission == AppPermission.manageSupervisor ||
            permission == AppPermission.viewUserManagement;
      case AppRole.supervisor:
        return false;
    }
  }

  static void requirePermission(AppRole role, AppPermission permission) {
    if (!allows(role, permission)) throw const PermissionDenied();
  }

  static bool canManageRole(AppRole actor, AppRole target) {
    return switch (target) {
      AppRole.generalAdmin => false, // Foundational account is protected.
      AppRole.ordinaryAdmin => actor == AppRole.generalAdmin,
      AppRole.supervisor => actor != AppRole.supervisor,
    };
  }

  /// A supervisor MUST NOT receive a user-management navigation entry.
  static bool getUserManagementMenuVisible(AppRole role) =>
      allows(role, AppPermission.viewUserManagement);
}

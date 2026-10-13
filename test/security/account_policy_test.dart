import 'package:adwas_personnel/core/security/account_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all routine operations remain available to all roles', () {
    const administrative = {
      AppPermission.addOrdinaryAdmin,
      AppPermission.manageOrdinaryAdmin,
      AppPermission.addSupervisor,
      AppPermission.manageSupervisor,
      AppPermission.viewUserManagement,
    };
    for (final permission in AppPermission.values) {
      if (administrative.contains(permission)) continue;
      for (final role in AppRole.values) {
        expect(AccountPolicy.allows(role, permission), isTrue,
            reason: '$role must keep $permission');
      }
    }
  });

  test('only general administration creates/manages ordinary administrators', () {
    for (final permission in [AppPermission.addOrdinaryAdmin,
      AppPermission.manageOrdinaryAdmin]) {
      expect(AccountPolicy.allows(AppRole.generalAdmin, permission), isTrue);
      expect(AccountPolicy.allows(AppRole.ordinaryAdmin, permission), isFalse);
      expect(AccountPolicy.allows(AppRole.supervisor, permission), isFalse);
    }
  });

  test('ordinary administration may manage supervisors but not general admin', () {
    for (final permission in [AppPermission.addSupervisor,
      AppPermission.manageSupervisor, AppPermission.viewUserManagement]) {
      expect(AccountPolicy.allows(AppRole.ordinaryAdmin, permission), isTrue);
      expect(AccountPolicy.allows(AppRole.generalAdmin, permission), isTrue);
      expect(AccountPolicy.allows(AppRole.supervisor, permission), isFalse);
    }
    expect(AccountPolicy.canManageRole(AppRole.generalAdmin,
      AppRole.generalAdmin), isFalse);
    expect(AccountPolicy.canManageRole(AppRole.ordinaryAdmin,
      AppRole.ordinaryAdmin), isFalse);
  });

  test('supervisor cannot see or call user management operations', () {
    expect(AccountPolicy.getUserManagementMenuVisible(AppRole.supervisor), isFalse);
    expect(() => AccountPolicy.requirePermission(AppRole.supervisor,
      AppPermission.addSupervisor), throwsA(isA<PermissionDenied>()));
  });
}

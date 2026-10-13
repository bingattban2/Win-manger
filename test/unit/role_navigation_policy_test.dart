import 'package:adwas_personnel/app/navigation/role_navigation_policy.dart';
import 'package:adwas_personnel/core/security/account_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supervisors retain operational menus without account management', () {
    final visible = RoleNavigationPolicy.visibleFor(AppRole.supervisor);
    expect(visible.any((item) => item.title == 'إدارة المستخدمين'), isFalse);
    expect(visible.any((item) => item.title == 'النقل الداخلي'), isTrue);
    expect(visible.any((item) => item.title == 'الفصل'), isTrue);
  });

  test('ordinary and general admins see user management', () {
    for (final role in [AppRole.generalAdmin, AppRole.ordinaryAdmin]) {
      expect(RoleNavigationPolicy.visibleFor(role)
          .any((item) => item.title == 'إدارة المستخدمين'), isTrue);
    }
  });
}

import 'package:adwas_personnel/core/security/account_models.dart';
import 'package:adwas_personnel/core/security/account_policy.dart';
import 'package:adwas_personnel/core/security/authentication_service.dart';
import 'package:adwas_personnel/core/security/user_management_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePersonnelDirectory implements PersonnelDirectory {
  @override
  Future<LinkedPersonnel?> findById(String personId) async {
    if (personId == 'p') {
      return const LinkedPersonnel(id: 'p', fullName: 'فرد مسجل',
        personnelNumber: '000123', isActive: true);
    }
    return null;
  }
}

void main() {
  test('ordinary administrators can create supervisors but not administrators', () async {
    final store = InMemoryAccountStore();
    await store.insert(const PersonnelAccount(id: 'ordinary',
      username: 'ordinary', personId: 'p', role: AppRole.ordinaryAdmin,
      passwordHash: 'fixture', isActive: true, isDeleted: false,
      createdBy: FoundationalAccount.id));
    final auth = OfflineAuthenticationService(store,
      verifyPassword: (password, hash) => password == hash);
    final session = (await auth.signIn('ordinary', 'fixture')).session!;
    final management = UserManagementService(store: store,
      authentication: auth, personnel: FakePersonnelDirectory());
    await expectLater(management.create(actor: session,
      role: AppRole.ordinaryAdmin, username: 'otheradmin',
      personId: 'p', password: 'Abc123!'),
      throwsA(isA<PermissionDenied>()));
    await expectLater(management.create(actor: session,
      role: AppRole.supervisor, username: 'invalid-person',
      personId: 'not-registered', password: 'Abc123!'),
      throwsA(isA<FormatException>()));
    final supervisor = await management.create(actor: session,
      role: AppRole.supervisor, username: 'validsupervisor',
      personId: 'p', password: 'Abc123!');
    expect(supervisor.createdBy, 'ordinary');
    expect(supervisor.personId, 'p');
    expect(supervisor.passwordHash, isNot(contains('Abc123!')));
    await management.deactivate(actor: session, targetId: supervisor.id);
    expect((await store.byId(supervisor.id))!.isDeleted, isTrue);
  });

  test('supervisors cannot call user management service directly', () async {
    final store = InMemoryAccountStore();
    await store.insert(const PersonnelAccount(id: 'sup', username: 'sup',
      personId: 'p', role: AppRole.supervisor, passwordHash: 'fixture',
      isActive: true, isDeleted: false,
      createdBy: FoundationalAccount.id));
    final auth = OfflineAuthenticationService(store,
      verifyPassword: (password, hash) => password == hash);
    final session = (await auth.signIn('sup', 'fixture')).session!;
    final management = UserManagementService(store: store,
      authentication: auth, personnel: FakePersonnelDirectory());
    await expectLater(management.create(actor: session,
      role: AppRole.supervisor, username: 'rejected',
      personId: 'p', password: 'Abc123!'),
      throwsA(isA<PermissionDenied>()));
  });
}

import 'package:adwas_personnel/core/security/account_models.dart';
import 'package:adwas_personnel/core/security/account_policy.dart';
import 'package:adwas_personnel/core/security/authentication_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bootstrap seeds exactly one protected general admin and is idempotent', () async {
    final store = InMemoryAccountStore();
    await AccountBootstrap.ensureFoundationalAdministrator(store);
    await AccountBootstrap.ensureFoundationalAdministrator(store);
    final account = await store.byId(FoundationalAccount.id);
    expect(account?.role, AppRole.generalAdmin);
    expect(account?.personId, isNull);
    expect(account?.username, 'adwas');
    expect(account?.passwordHash, isNot(contains(String.fromCharCodes([97, 100, 119, 97, 115, 50, 48, 49, 57, 49, 49, 51]))));
    await expectLater(store.update(account!.copyWith(isActive: false)),
      throwsA(isA<PermissionDenied>()));
  });

  test('sign-in and live session authorization, logout, and forged sessions', () async {
    final store = InMemoryAccountStore();
    await store.insert(const PersonnelAccount(id: 'one', username: 'manager',
      personId: 'person1', role: AppRole.ordinaryAdmin,
      passwordHash: 'fixture', isActive: true, isDeleted: false,
      createdBy: FoundationalAccount.id));
    var now = DateTime.utc(2026, 10, 13, 10);
    final authentication = OfflineAuthenticationService(store,
      clock: () => now,
      verifyPassword: (password, hash) => password == hash);
    expect((await authentication.signIn('MANAGER', 'fixture')).status,
      SignInStatus.success);
    final successful = await authentication.signIn(' manager ', 'fixture');
    final session = successful.session!;
    final forged = LocalSession(accountId: 'one', token: session.token,
      lastActiveUtc: now);
    await expectLater(authentication.requirePermission(forged,
      AppPermission.dashboard), throwsA(isA<PermissionDenied>()));
    expect((await authentication.requirePermission(session,
      AppPermission.dashboard)).id, 'one');
    await expectLater(authentication.requirePermission(session,
      AppPermission.addOrdinaryAdmin), throwsA(isA<PermissionDenied>()));
    now = now.add(const Duration(minutes: 11));
    await expectLater(authentication.requirePermission(session,
      AppPermission.dashboard), throwsA(isA<PermissionDenied>()));
    final fresh = (await authentication.signIn('manager', 'fixture')).session!;
    authentication.signOut(fresh);
    await expectLater(authentication.requirePermission(fresh,
      AppPermission.dashboard), throwsA(isA<PermissionDenied>()));
  });

  test('failed attempts throttle, deactivated accounts deny existing sessions', () async {
    final store = InMemoryAccountStore();
    await store.insert(const PersonnelAccount(id: 'two', username: 'super',
      personId: 'p2', role: AppRole.supervisor,
      passwordHash: 'fixture', isActive: true, isDeleted: false,
      createdBy: FoundationalAccount.id));
    var now = DateTime.utc(2026, 10, 13, 10);
    final authentication = OfflineAuthenticationService(store,
      clock: () => now,
      verifyPassword: (password, hash) => password == hash);
    for (var index = 0; index < 3; index++) {
      expect((await authentication.signIn('super', 'wrong')).status,
        SignInStatus.invalidCredentials);
    }
    expect((await authentication.signIn('super', 'fixture')).status,
      SignInStatus.temporarilyBlocked);
    now = now.add(const Duration(seconds: 2));
    final session = (await authentication.signIn('super', 'fixture')).session!;
    await store.update((await store.byId('two'))!.copyWith(
      isActive: false, isDeleted: true));
    await expectLater(authentication.requirePermission(session,
      AppPermission.dashboard), throwsA(isA<PermissionDenied>()));
    expect((await authentication.signIn('super', 'fixture')).status,
      SignInStatus.invalidCredentials);
  });
}

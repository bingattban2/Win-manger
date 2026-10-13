import 'dart:math';

import 'account_models.dart';
import 'account_policy.dart';
import 'authentication_service.dart';
import 'password_verifier.dart';

class LinkedPersonnel {
  const LinkedPersonnel({required this.id, required this.fullName,
    required this.personnelNumber, required this.isActive});
  final String id;
  final String fullName;
  final String personnelNumber;
  final bool isActive;
}

/// Production implementation must resolve against the real persons table.
abstract interface class PersonnelDirectory {
  Future<LinkedPersonnel?> findById(String personId);
}

/// Real business authorization is performed in this application service,
/// never inferred from whether the navigation entry is hidden.
class UserManagementService {
  UserManagementService({required this.store, required this.authentication,
    required this.personnel});

  final AccountStore store;
  final OfflineAuthenticationService authentication;
  final PersonnelDirectory personnel;

  Future<PersonnelAccount> create({required LocalSession actor,
    required AppRole role, required String username,
    required String personId, required String password}) async {
    final permission = role == AppRole.ordinaryAdmin
        ? AppPermission.addOrdinaryAdmin : AppPermission.addSupervisor;
    if (role == AppRole.generalAdmin) throw const PermissionDenied();
    final principal = await authentication.requirePermission(actor, permission);
    if (!AccountPolicy.canManageRole(principal.role, role)) {
      throw const PermissionDenied();
    }
    final normalized = AccountNames.normalize(username);
    if (!AccountNames.validUsername(normalized) ||
        normalized == FoundationalAccount.username) {
      throw const FormatException('Invalid username');
    }
    final person = await personnel.findById(personId);
    if (person == null || !person.isActive ||
        person.fullName.trim().isEmpty || person.personnelNumber.isEmpty) {
      throw const FormatException('User must match an active registered person');
    }
    if (await store.byUsername(normalized) != null) {
      throw StateError('Account already exists');
    }
    final hash = PasswordVerifier.hashNew(password);
    final random = Random.secure();
    final id = List<int>.generate(16, (_) => random.nextInt(256))
        .map((n) => n.toRadixString(16).padLeft(2, '0')).join();
    final account = PersonnelAccount(id: id, username: normalized,
      personId: person.id, role: role, passwordHash: hash,
      isActive: true, isDeleted: false, createdBy: principal.id);
    await store.insert(account);
    return account;
  }

  Future<void> changePassword({required LocalSession actor,
    required String targetId, required String newPassword}) async {
    final principal = await authentication.requirePermission(actor,
        AppPermission.viewUserManagement);
    final target = await store.byId(targetId);
    if (target == null) throw StateError('Missing account');
    _authorizeTarget(principal.role, target.role);
    await store.update(target.copyWith(
      passwordHash: PasswordVerifier.hashNew(newPassword),
    ));
  }

  Future<void> deactivate({required LocalSession actor,
    required String targetId}) async {
    final principal = await authentication.requirePermission(actor,
        AppPermission.viewUserManagement);
    final target = await store.byId(targetId);
    if (target == null) throw StateError('Missing account');
    _authorizeTarget(principal.role, target.role);
    await store.update(target.copyWith(isActive: false, isDeleted: true));
  }

  void _authorizeTarget(AppRole actor, AppRole target) {
    if (!AccountPolicy.canManageRole(actor, target)) {
      throw const PermissionDenied();
    }
  }
}

import 'account_policy.dart';

/// The fixed administrator has no linked personnel identity.
/// A production adapter seeds this hashed identity transactionally into
/// encrypted app_users, not into an unencrypted application database.
abstract final class FoundationalAccount {
  static const id = '00000000-0000-4000-8000-000000000099';
  static const username = 'adwas';
  static const storedVerifier =
      r'pbkdf2_sha256$210000$VmrezvLtEP6CecM2PMKPYg==$oM0M8QinKBZMQ8HgsVF07x3y0bs4lHD/RcRLLTv3EfI=';
}

class PersonnelAccount {
  const PersonnelAccount({
    required this.id,
    required this.username,
    required this.personId,
    required this.role,
    required this.passwordHash,
    required this.isActive,
    required this.isDeleted,
    required this.createdBy,
  });

  final String id;
  final String username;
  final String? personId;
  final AppRole role;
  final String passwordHash;
  final bool isActive;
  final bool isDeleted;
  final String? createdBy;

  PersonnelAccount copyWith({String? passwordHash, bool? isActive, bool? isDeleted}) {
    return PersonnelAccount(
      id: id,
      username: username,
      personId: personId,
      role: role,
      passwordHash: passwordHash ?? this.passwordHash,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdBy: createdBy,
    );
  }
}

abstract final class AccountNames {
  static String normalize(String input) => input.trim().toLowerCase();
  static bool validUsername(String input) =>
      RegExp(r'^[a-z][a-z0-9._-]{2,39}$').hasMatch(normalize(input));
}

abstract interface class AccountStore {
  Future<PersonnelAccount?> byUsername(String normalizedUsername);
  Future<PersonnelAccount?> byId(String id);
  Future<void> insert(PersonnelAccount account);
  Future<void> update(PersonnelAccount account);
}

/// For test fixtures only. NOT a production persistence adapter.
class InMemoryAccountStore implements AccountStore {
  final Map<String, PersonnelAccount> _users = {};

  @override
  Future<PersonnelAccount?> byUsername(String normalizedUsername) async {
    for (final item in _users.values) {
      if (AccountNames.normalize(item.username) == normalizedUsername) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<PersonnelAccount?> byId(String id) async => _users[id];

  @override
  Future<void> insert(PersonnelAccount account) async {
    if (_users.containsKey(account.id) ||
        await byUsername(AccountNames.normalize(account.username)) != null) {
      throw StateError('Account already exists');
    }
    if (account.role == AppRole.generalAdmin &&
        account.id != FoundationalAccount.id) {
      throw const PermissionDenied();
    }
    _users[account.id] = account;
  }

  @override
  Future<void> update(PersonnelAccount account) async {
    final old = _users[account.id];
    if (old == null) throw StateError('Missing account');
    if (old.username != account.username || old.role != account.role ||
        old.personId != account.personId || old.createdBy != account.createdBy) {
      throw const PermissionDenied();
    }
    if (old.id == FoundationalAccount.id &&
        (!account.isActive || account.isDeleted ||
            account.passwordHash != old.passwordHash)) {
      throw const PermissionDenied();
    }
    _users[account.id] = account;
  }
}

abstract final class AccountBootstrap {
  static Future<void> ensureFoundationalAdministrator(AccountStore store) async {
    final byId = await store.byId(FoundationalAccount.id);
    final byName = await store.byUsername(FoundationalAccount.username);
    if (byId != null || byName != null) {
      if (byId?.id != FoundationalAccount.id ||
          byName?.id != FoundationalAccount.id ||
          byId?.role != AppRole.generalAdmin ||
          byId?.isActive != true ||
          byId?.isDeleted != false ||
          byId?.personId != null ||
          byId?.passwordHash != FoundationalAccount.storedVerifier) {
        throw StateError('Foundational account integrity check failed');
      }
      return;
    }
    await store.insert(const PersonnelAccount(
      id: FoundationalAccount.id,
      username: FoundationalAccount.username,
      personId: null,
      role: AppRole.generalAdmin,
      passwordHash: FoundationalAccount.storedVerifier,
      isActive: true,
      isDeleted: false,
      createdBy: null,
    ));
  }
}

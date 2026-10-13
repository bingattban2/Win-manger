import 'dart:math';

import 'account_models.dart';
import 'account_policy.dart';
import 'password_verifier.dart';

/// Authentication is local-only. A production account adapter must connect
/// to encrypted SQLite before exposing the login screen to end users.
/// This service intentionally contains no HTTP clients or telemetry.
class LocalSession {
  LocalSession({required this.accountId, required this.token,
    required this.lastActiveUtc});

  final String accountId;
  final String token;
  DateTime lastActiveUtc;
  bool isClosed = false;

  bool isExpired(DateTime now) => isClosed ||
      now.difference(lastActiveUtc) >= const Duration(minutes: 10) ||
      now.isBefore(lastActiveUtc);

  void close() => isClosed = true;
}

enum SignInStatus { success, invalidCredentials, temporarilyBlocked }

class SignInResult {
  const SignInResult(this.status, [this.session]);
  final SignInStatus status;
  final LocalSession? session;
}

class OfflineAuthenticationService {
  OfflineAuthenticationService(this.store, {DateTime Function()? clock,
    bool Function(String, String)? verifyPassword})
      : _clock = clock ?? DateTime.now,
        _verify = verifyPassword ?? PasswordVerifier.verify;

  final AccountStore store;
  final DateTime Function() _clock;
  final bool Function(String, String) _verify;
  final Map<String, int> _failures = {};
  final Map<String, DateTime> _nextAllowed = {};
  final Map<String, LocalSession> _issuedSessions = {};

  Future<SignInResult> signIn(String username, String password) async {
    final name = AccountNames.normalize(username);
    final now = _clock().toUtc();
    if (now.isBefore(_nextAllowed[name] ?? DateTime.utc(1970))) {
      return const SignInResult(SignInStatus.temporarilyBlocked);
    }
    final account = await store.byUsername(name);
    // A dummy verification prevents the unknown-user path from returning
    // immediately, reducing username enumeration by timing differences.
    final verified = _verify(password,
        account?.passwordHash ?? FoundationalAccount.storedVerifier);
    if (account == null || !account.isActive || account.isDeleted || !verified) {
      final strikes = (_failures[name] ?? 0) + 1;
      _failures[name] = strikes;
      if (strikes >= 3) {
        final wait = 1 << min(strikes - 3, 6);
        _nextAllowed[name] = now.add(Duration(seconds: wait));
      }
      return const SignInResult(SignInStatus.invalidCredentials);
    }
    _failures.remove(name);
    _nextAllowed.remove(name);
    final secure = Random.secure();
    final token = List<int>.generate(32, (_) => secure.nextInt(256))
        .map((n) => n.toRadixString(16).padLeft(2, '0')).join();
    final session = LocalSession(
      accountId: account.id, token: token, lastActiveUtc: now,
    );
    _issuedSessions[token] = session;
    return SignInResult(SignInStatus.success, session);
  }

  Future<PersonnelAccount> requirePermission(LocalSession session,
      AppPermission permission) async {
    final now = _clock().toUtc();
    if (!identical(_issuedSessions[session.token], session) || session.isExpired(now)) {
      session.close();
      throw const PermissionDenied();
    }
    final account = await store.byId(session.accountId);
    if (account == null || !account.isActive || account.isDeleted) {
      session.close();
      throw const PermissionDenied();
    }
    AccountPolicy.requirePermission(account.role, permission);
    session.lastActiveUtc = now;
    return account;
  }

  void signOut(LocalSession session) {
    _issuedSessions.remove(session.token);
    session.close();
  }
}

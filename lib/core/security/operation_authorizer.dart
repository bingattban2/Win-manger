import 'package:adwas_personnel/core/security/account_policy.dart';
import 'package:adwas_personnel/core/security/authentication_service.dart';

class AuthorizedOperator {
  const AuthorizedOperator(this.accountId, this.role);

  final String accountId;
  final AppRole role;
}

/// Security boundary for ALL state-changing commands, independently of UI.
abstract interface class OperationAuthorizer {
  Future<AuthorizedOperator> require(
    LocalSession session,
    AppPermission permission,
  );
}

class OfflineOperationAuthorizer implements OperationAuthorizer {
  const OfflineOperationAuthorizer(this.authentication);

  final OfflineAuthenticationService authentication;

  @override
  Future<AuthorizedOperator> require(
    LocalSession session,
    AppPermission permission,
  ) async {
    final user = await authentication.requirePermission(session, permission);
    return AuthorizedOperator(user.id, user.role);
  }
}

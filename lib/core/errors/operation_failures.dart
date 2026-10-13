/// Typed operation failures. Errors are safe for Arabic UI translation.
enum OperationFailureCode {
  invalidInput,
  unauthenticated,
  permissionDenied,
  notFound,
  businessRule,
  stalePreview,
  confirmationRequired,
  alreadySubmitted,
  persistenceUnavailable,
}

class OperationFailure implements Exception {
  const OperationFailure(this.code, this.message);

  final OperationFailureCode code;
  final String message;

  @override
  String toString() => 'OperationFailure(${code.name}): $message';
}

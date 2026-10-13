import 'package:adwas_personnel/core/errors/operation_failures.dart';
import 'package:adwas_personnel/core/transactions/operation_pipeline.dart';

/// Deliberately fail closed until the encrypted SQLite adapter is connected.
/// Never store real personnel into plaintext or into a fixture repository.
class ClosedTransactionExecutor implements TransactionExecutor {
  const ClosedTransactionExecutor();

  @override
  Future<T> runInTransaction<T>(Future<T> Function() transactionBody) async {
    throw const OperationFailure(
      OperationFailureCode.persistenceUnavailable,
      'Encrypted SQLite transaction adapter is not yet configured',
    );
  }
}

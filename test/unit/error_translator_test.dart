import 'package:adwas_personnel/core/errors/error_translator.dart';
import 'package:adwas_personnel/core/errors/operation_failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every pipeline failure maps to an Arabic message', () {
    for (final code in OperationFailureCode.values) {
      final message = ErrorTranslator.operation(OperationFailure(code, 'secret'));
      expect(message, isNotEmpty);
      expect(message, isNot(contains('secret')));
    }
  });
}

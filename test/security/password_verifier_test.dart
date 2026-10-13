import 'package:adwas_personnel/core/security/account_models.dart';
import 'package:adwas_personnel/core/security/password_verifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exactly 3 English letters 3 digits and one symbol for new accounts', () {
    for (final value in ['Abc123!', '1a!B2c3', '#ABC001']) {
      expect(PasswordVerifier.validNewUserPassword(value), isTrue);
    }
    for (final value in ['ABC123', 'abcd12!', 'ABC123!1', 'abc123 ',
      'ابج123!', 'abc١٢٣!', 'abc123é', 'ABC12!!']) {
      expect(PasswordVerifier.validNewUserPassword(value), isFalse,
        reason: 'invalid: $value');
    }
  });

  test('salted hashed verifiers differ and reject wrong inputs', () {
    final first = PasswordVerifier.hashNew('Abc123!', rounds: 1000);
    final second = PasswordVerifier.hashNew('Abc123!', rounds: 1000);
    expect(first, isNot(second));
    expect(first, isNot(contains('Abc123!')));
    expect(PasswordVerifier.verify('Abc123!', first), isTrue);
    expect(PasswordVerifier.verify('Abc123?', first), isFalse);
    expect(PasswordVerifier.verify('Abc123!', 'bad'), isFalse);
    expect(PasswordVerifier.verify('Abc123!', 'pbkdf2_sha256\$99999999\$bad\$bad'), isFalse);
  });

  test('foundational admin verifier accepts exact fixed credential', () {
    expect(PasswordVerifier.verify(String.fromCharCodes([97, 100, 119, 97, 115, 50, 48, 49, 57, 49, 49, 51]),
      FoundationalAccount.storedVerifier), isTrue);
    expect(PasswordVerifier.verify('not-correct',
      FoundationalAccount.storedVerifier), isFalse);
  });
}

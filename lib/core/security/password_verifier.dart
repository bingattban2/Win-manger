import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256, random 128-bit salt, versioned verifier string.
/// No plaintext password is saved. Call expensive verification off the UI
/// isolate when connecting to the production encrypted repository.
abstract final class PasswordVerifier {
  static const int defaultRounds = 210000;

  static bool validNewUserPassword(String value) {
    if (value.runes.length != 7) return false;
    var letters = 0;
    var digits = 0;
    var symbols = 0;
    for (final rune in value.runes) {
      if ((rune >= 65 && rune <= 90) || (rune >= 97 && rune <= 122)) {
        letters++;
      } else if (rune >= 48 && rune <= 57) {
        digits++;
      } else if (rune >= 33 && rune <= 126) {
        symbols++;
      } else {
        return false;
      }
    }
    return letters == 3 && digits == 3 && symbols == 1;
  }

  static String hashNew(String password, {int rounds = defaultRounds}) {
    if (!validNewUserPassword(password)) {
      throw const FormatException('Invalid account password policy');
    }
    if (rounds < 1000) throw const FormatException('Insufficient KDF rounds');
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final digest = _derive(password, salt, rounds);
    return 'pbkdf2_sha256\$$rounds\$${base64.encode(salt)}\$${base64.encode(digest)}';
  }

  static bool verify(String suppliedPassword, String storedVerifier) {
    try {
      final parts = storedVerifier.split(r'$');
      if (parts.length != 4 || parts[0] != 'pbkdf2_sha256') return false;
      final rounds = int.parse(parts[1]);
      if (rounds < 1000 || rounds > 2000000) return false;
      final salt = base64.decode(parts[2]);
      final expected = base64.decode(parts[3]);
      if (salt.length != 16 || expected.length != 32) return false;
      final actual = _derive(suppliedPassword, salt, rounds);
      var difference = 0;
      for (var i = 0; i < expected.length; i++) {
        difference |= actual[i] ^ expected[i];
      }
      return difference == 0;
    } on FormatException {
      return false;
    } on ArgumentError {
      return false;
    }
  }

  static Uint8List _derive(String password, List<int> salt, int rounds) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final input = Uint8List(salt.length + 4);
    input.setRange(0, salt.length, salt);
    input[input.length - 1] = 1;
    var current = hmac.convert(input).bytes;
    final derived = Uint8List.fromList(current);
    for (var round = 1; round < rounds; round++) {
      current = hmac.convert(current).bytes;
      for (var i = 0; i < derived.length; i++) {
        derived[i] ^= current[i];
      }
    }
    return derived;
  }
}

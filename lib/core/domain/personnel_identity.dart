import 'dart:math';

/// Original visible "الرقم (ع)" and its stable collision-detection key.
///
/// Never parse the business number as an int: leading zeroes are significant.
/// Database triggers independently verify normalization on write.
class PersonnelNumber {
  PersonnelNumber(String original)
      : original = original.trim(),
        normalized = normalize(original) {
    if (normalized.isEmpty) {
      throw const FormatException('الرقم (ع) لا يمكن أن يكون فارغًا');
    }
  }

  final String original;
  final String normalized;

  static String normalize(String source) {
    final output = StringBuffer();
    for (final rune in source.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        output.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        output.writeCharCode(0x30 + rune - 0x06F0);
      } else if (rune == 0x20 ||
          (rune >= 0x09 && rune <= 0x0D) ||
          rune == 0x00A0) {
        // Spaces in copied spreadsheet IDs should never create new identities.
        continue;
      } else {
        output.writeCharCode(rune);
      }
    }
    return output.toString();
  }
}

/// Search-only Arabic normalizer; never rewrite the person's displayed name.
abstract final class ArabicNameSearch {
  static String normalize(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }
}

/// UUID v4 built from an OS-backed CSPRNG; no package/network dependency.
abstract final class PersonId {
  static String newId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

/// Business identity: immutable person ID, separate visible and search keys.
class PersonnelIdentity {
  PersonnelIdentity._({
    required this.personId,
    required this.personnelNumber,
    required this.fullName,
    required this.normalizedName,
  });

  factory PersonnelIdentity.create({
    required String fullName,
    required String personnelNumber,
  }) {
    return PersonnelIdentity._build(
      id: PersonId.newId(),
      fullName: fullName,
      personnelNumber: personnelNumber,
    );
  }

  factory PersonnelIdentity.rehydrate({
    required String personId,
    required String fullName,
    required String personnelNumber,
  }) {
    if (personId.trim().isEmpty) {
      throw const FormatException('معرف الفرد الداخلي مطلوب');
    }
    return PersonnelIdentity._build(
      id: personId,
      fullName: fullName,
      personnelNumber: personnelNumber,
    );
  }

  static PersonnelIdentity _build({
    required String id,
    required String fullName,
    required String personnelNumber,
  }) {
    final name = fullName.trim();
    final searchable = ArabicNameSearch.normalize(name);
    if (name.isEmpty || searchable.isEmpty) {
      throw const FormatException('اسم الفرد مطلوب');
    }
    return PersonnelIdentity._(
      personId: id,
      personnelNumber: PersonnelNumber(personnelNumber),
      fullName: name,
      normalizedName: searchable,
    );
  }

  final String personId;
  final PersonnelNumber personnelNumber;
  final String fullName;
  final String normalizedName;

  /// Correct a record's mutable identity fields while retaining its person_id.
  /// The application service will append person_identity_history in its phase.
  PersonnelIdentity corrected({String? fullName, String? personnelNumber}) {
    return PersonnelIdentity._build(
      id: personId,
      fullName: fullName ?? this.fullName,
      personnelNumber: personnelNumber ?? this.personnelNumber.original,
    );
  }
}

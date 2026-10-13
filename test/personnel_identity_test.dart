import 'package:adwas_personnel/core/domain/personnel_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Arabic, Persian and Western numerals share a normalized key', () {
    expect(PersonnelNumber('٠٠١٢').normalized, '0012');
    expect(PersonnelNumber('۰۰۱۲').normalized, '0012');
    expect(PersonnelNumber('0012').normalized, '0012');
    expect(PersonnelNumber(' ٠ ٠ ١ ٢ ').normalized, '0012');
  });

  test('leading zeroes survive exactly in original and normalized values', () {
    final number = PersonnelNumber('٠٠١٢');
    expect(number.original, '٠٠١٢');
    expect(number.normalized, '0012');
    expect(PersonnelNumber('0012').normalized, isNot('12'));
  });

  test('blank business identifiers cannot be created', () {
    expect(() => PersonnelNumber('   '), throwsFormatException);
    expect(() => PersonnelNumber('  \t  '), throwsFormatException);
  });

  test('person IDs are distinct UUID v4 identifiers', () {
    final ids = List<String>.generate(200, (_) => PersonId.newId());
    expect(ids.toSet().length, 200);
    for (final id in ids) {
      expect(id, matches(RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    }
  });

  test('name and number corrections preserve the immutable person ID', () {
    final original = PersonnelIdentity.create(
      fullName: 'أحمد سالم', personnelNumber: '٠٠١٢');
    final updated = original.corrected(
      fullName: 'احمد سالم باحمد', personnelNumber: '0013');
    expect(updated.personId, original.personId);
    expect(updated.personnelNumber.normalized, '0013');
    expect(updated.fullName, 'احمد سالم باحمد');
    expect(original.personnelNumber.normalized, '0012');
  });

  test('search normalizer does not change the original displayed name', () {
    final identity = PersonnelIdentity.create(
        fullName: 'أَحْمَد  السّالِم', personnelNumber: '12');
    expect(identity.fullName, 'أَحْمَد  السّالِم');
    expect(identity.normalizedName, 'احمد السالم');
  });
}

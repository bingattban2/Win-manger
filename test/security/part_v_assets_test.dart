import 'package:adwas_personnel/core/config/project_info.dart';
import 'package:adwas_personnel/core/security/account_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Part V policy overlay is bundled and contains hashed-only admin', () async {
    final script = await rootBundle.loadString(
      'assets/database/part_v_authorization.sql');
    expect(script, contains('trg_foundation_account_immutable_identity'));
    expect(script, contains('trg_account_no_hard_delete'));
    expect(script, contains(FoundationalAccount.storedVerifier));
    expect(script, isNot(contains(String.fromCharCodes([97, 100, 119, 97, 115, 50, 48, 49, 57, 49, 49, 51]))));
    expect(ProjectInfo.nameArabic, 'التمام اليومي');
    expect(ProjectInfo.version, '0.0.6');
    expect(ProjectInfo.isProductionReady, isFalse);
  });
}

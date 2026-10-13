import 'package:adwas_personnel/core/config/project_info.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('business constraints and effective-date query are bundled locally', () async {
    final rules = await rootBundle.loadString('assets/database/part_iv_rules.sql');
    final statistics = await rootBundle.loadString(
        'assets/database/part_iv_statistics.sql');
    expect(rules, contains('v_monthly_cell_events'));
    expect(rules, contains('ux_one_transfer_person_day'));
    expect(rules, contains('trg_p4_attendance_insert'));
    expect(statistics, contains('__UNPREPARED__'));
    expect(statistics, contains(':report_date'));
  });

  test('Part IV keeps the Arabic Windows application identity', () {
    expect(ProjectInfo.nameArabic, 'التمام اليومي');
    expect(ProjectInfo.version, '0.0.4');
    expect(ProjectInfo.isProductionReady, isFalse);
  });
}

import 'package:adwas_personnel/core/domain/schema_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog contains all required tables exactly once', () {
    expect(DatabaseSchemaCatalog.version, 1);
    expect(DatabaseSchemaCatalog.tableNames.length, 29);
    expect(DatabaseSchemaCatalog.tableNames.toSet().length, 29);
    for (final requiredName in <String>[
      'persons', 'person_identity_history', 'sites',
      'person_site_assignments', 'daily_attendance', 'monthly_archives',
      'monthly_archive_persons', 'monthly_archive_days', 'app_users',
      'audit_events', 'schema_migrations',
    ]) {
      expect(DatabaseSchemaCatalog.tableNames, contains(requiredName));
    }
  });

  test('SQL asset is bundled and declares the required unique key', () async {
    final schema = await rootBundle.loadString('assets/database/schema_v1.sql');
    final seed = await rootBundle.loadString('assets/database/seed_v1.sql');
    expect(schema, contains('UNIQUE(person_id,attendance_date)'));
    expect(schema, contains('trg_assignments_no_overlap_insert'));
    expect(schema, contains('trg_archive_sealed_update'));
    expect(seed, contains('غير محدد'));
    expect(seed, contains(SystemReferences.undefinedSiteId));
  });
}

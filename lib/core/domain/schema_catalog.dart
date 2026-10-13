/// Part III single-source inventory for schema smoke tests and the foundation UI.
/// Authoritative constraints are in assets/database/schema_v1.sql.
abstract final class DatabaseSchemaCatalog {
  static const int version = 1;
  static const List<String> tableNames = <String>[
    'persons',
    'personnel_number_registry',
    'person_identity_history',
    'sites',
    'site_name_history',
    'person_site_assignments',
    'attendance_statuses',
    'attendance_status_history',
    'daily_attendance',
    'attendance_revision_history',
    'internal_transfers',
    'external_transfers',
    'dismissals',
    'attribute_definitions',
    'person_attribute_values',
    'monthly_archives',
    'monthly_archive_persons',
    'monthly_archive_days',
    'app_users',
    'audit_events',
    'authentication_events',
    'import_batches',
    'import_rejected_rows',
    'export_history',
    'backup_history',
    'scheduled_backup_state',
    'application_settings',
    'schema_migrations',
    // Additional normalized archive site timeline table.
    'monthly_archive_site_segments',
  ];
}

/// Identifiers and colors in seed_v1.sql. Not user data, not passwords.
abstract final class SystemReferences {
  static const String undefinedSiteId =
      '00000000-0000-4000-8000-000000000001';
  static const Map<String, int> statusColors = <String, int>{
    'موجود': 0xFF81D4FA,
    'إجازة': 0xFF4CAF50,
    'غياب': 0xFFF44336,
    'إذن': 0xFFFFEB3B,
  };
}

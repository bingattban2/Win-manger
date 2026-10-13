-- Altamam Al-Yawmi / التمام اليومي
-- PART III: canonical normalized SQLite schema, version 1.
-- This schema is executed by in-memory SQLite tests now. Runtime persistent
-- storage MUST NOT be enabled until the encrypted SQLite backend is verified.
-- All IDs and business dates are TEXT; operation timestamps are UTC ISO-8601.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS app_users (
  id TEXT NOT NULL PRIMARY KEY,
  username TEXT NOT NULL CHECK(length(trim(username)) > 0),
  normalized_username TEXT NOT NULL UNIQUE CHECK(length(trim(normalized_username)) > 0),
  person_id TEXT REFERENCES persons(id) ON DELETE RESTRICT,
  role TEXT NOT NULL CHECK(role IN ('GENERAL_ADMIN','ORDINARY_ADMIN','SUPERVISOR')),
  password_hash TEXT NOT NULL CHECK(length(password_hash) > 0),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),
  is_deleted INTEGER NOT NULL DEFAULT 0 CHECK(is_deleted IN (0,1)),
  created_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  CHECK(role = 'GENERAL_ADMIN' OR person_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS persons (
  id TEXT NOT NULL PRIMARY KEY,
  personnel_number TEXT NOT NULL CHECK(length(trim(personnel_number)) > 0),
  normalized_personnel_number TEXT NOT NULL UNIQUE CHECK(length(trim(normalized_personnel_number)) > 0),
  full_name TEXT NOT NULL CHECK(length(trim(full_name)) > 0),
  normalized_name TEXT NOT NULL CHECK(length(trim(normalized_name)) > 0),
  lifecycle_status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK(lifecycle_status IN ('ACTIVE','EXTERNALLY_TRANSFERRED','DISMISSED')),
  created_at TEXT NOT NULL,
  created_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  updated_at TEXT NOT NULL,
  updated_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT
);


-- Permanent reservation of previously held business numbers. Corrections may
-- change a person's display number but must not free that number for another
-- identity; prevents conflicts with archived or historical references.
CREATE TABLE IF NOT EXISTS personnel_number_registry (
  normalized_number TEXT NOT NULL PRIMARY KEY,
  person_id TEXT NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
  reserved_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_personnel_number_registry_person
  ON personnel_number_registry(person_id);

CREATE TRIGGER IF NOT EXISTS trg_number_registry_insert_check
BEFORE INSERT ON persons
WHEN EXISTS(SELECT 1 FROM personnel_number_registry r
  WHERE r.normalized_number=NEW.normalized_personnel_number AND r.person_id <> NEW.id)
BEGIN SELECT RAISE(ABORT,'business number is reserved for another person'); END;
CREATE TRIGGER IF NOT EXISTS trg_number_registry_insert
AFTER INSERT ON persons
BEGIN
  INSERT OR IGNORE INTO personnel_number_registry
    (normalized_number,person_id,reserved_at)
  VALUES (NEW.normalized_personnel_number,NEW.id,NEW.created_at);
END;
CREATE TRIGGER IF NOT EXISTS trg_number_registry_update_check
BEFORE UPDATE OF personnel_number,normalized_personnel_number ON persons
WHEN EXISTS(SELECT 1 FROM personnel_number_registry r
  WHERE r.normalized_number=NEW.normalized_personnel_number AND r.person_id <> NEW.id)
BEGIN SELECT RAISE(ABORT,'business number is reserved for another person'); END;
CREATE TRIGGER IF NOT EXISTS trg_number_registry_update
AFTER UPDATE OF personnel_number,normalized_personnel_number ON persons
BEGIN
  INSERT OR IGNORE INTO personnel_number_registry
    (normalized_number,person_id,reserved_at)
  VALUES (NEW.normalized_personnel_number,NEW.id,NEW.updated_at);
END;
CREATE TRIGGER IF NOT EXISTS trg_number_registry_no_update
BEFORE UPDATE ON personnel_number_registry
BEGIN SELECT RAISE(ABORT,'historical business number reservation is immutable'); END;
CREATE TRIGGER IF NOT EXISTS trg_number_registry_no_delete
BEFORE DELETE ON personnel_number_registry
BEGIN SELECT RAISE(ABORT,'historical business number reservation cannot be deleted'); END;

CREATE TABLE IF NOT EXISTS audit_events (
  id TEXT NOT NULL PRIMARY KEY,
  operation_type TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT,
  target_display_name TEXT NOT NULL DEFAULT '',
  actor_user_id TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  executed_at TEXT NOT NULL,
  effective_date TEXT,
  old_values TEXT,
  new_values TEXT,
  operation_group_id TEXT,
  result TEXT NOT NULL,
  previous_hash TEXT,
  event_hash TEXT NOT NULL CHECK(length(event_hash) > 0)
);

CREATE TABLE IF NOT EXISTS person_identity_history (
  id TEXT NOT NULL PRIMARY KEY,
  person_id TEXT NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
  old_name TEXT NOT NULL,
  new_name TEXT NOT NULL,
  old_personnel_number TEXT NOT NULL,
  new_personnel_number TEXT NOT NULL,
  changed_at TEXT NOT NULL,
  changed_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  audit_event_id TEXT REFERENCES audit_events(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS sites (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL CHECK(length(trim(name)) > 0),
  normalized_name TEXT NOT NULL UNIQUE CHECK(length(trim(normalized_name)) > 0),
  is_system_site INTEGER NOT NULL DEFAULT 0 CHECK(is_system_site IN (0,1)),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS site_name_history (
  id TEXT NOT NULL PRIMARY KEY,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  old_name TEXT NOT NULL,
  new_name TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  changed_at TEXT NOT NULL,
  changed_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS person_site_assignments (
  id TEXT NOT NULL PRIMARY KEY,
  person_id TEXT NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  effective_from TEXT NOT NULL CHECK(length(effective_from)=10),
  effective_to_exclusive TEXT CHECK(effective_to_exclusive IS NULL OR length(effective_to_exclusive)=10),
  assignment_reason TEXT NOT NULL CHECK(length(trim(assignment_reason)) > 0),
  created_at TEXT NOT NULL,
  created_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  CHECK(effective_to_exclusive IS NULL OR effective_from < effective_to_exclusive)
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_person_one_open_assignment
  ON person_site_assignments(person_id) WHERE effective_to_exclusive IS NULL;
CREATE INDEX IF NOT EXISTS ix_assignments_person_period
  ON person_site_assignments(person_id,effective_from,effective_to_exclusive);
CREATE INDEX IF NOT EXISTS ix_assignments_site_period
  ON person_site_assignments(site_id,effective_from,effective_to_exclusive);

CREATE TRIGGER IF NOT EXISTS trg_assignments_no_overlap_insert
BEFORE INSERT ON person_site_assignments
BEGIN
  SELECT RAISE(ABORT, 'overlapping person site assignment')
  WHERE EXISTS (
    SELECT 1 FROM person_site_assignments x
    WHERE x.person_id = NEW.person_id
      AND NEW.effective_from < COALESCE(x.effective_to_exclusive,'9999-12-31')
      AND x.effective_from < COALESCE(NEW.effective_to_exclusive,'9999-12-31')
  );
END;
CREATE TRIGGER IF NOT EXISTS trg_assignments_no_overlap_update
BEFORE UPDATE ON person_site_assignments
BEGIN
  SELECT RAISE(ABORT, 'overlapping person site assignment')
  WHERE EXISTS (
    SELECT 1 FROM person_site_assignments x
    WHERE x.person_id = NEW.person_id AND x.id <> OLD.id
      AND NEW.effective_from < COALESCE(x.effective_to_exclusive,'9999-12-31')
      AND x.effective_from < COALESCE(NEW.effective_to_exclusive,'9999-12-31')
  );
END;

CREATE TABLE IF NOT EXISTS attendance_statuses (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL CHECK(length(trim(name)) > 0),
  short_code TEXT NOT NULL CHECK(length(trim(short_code)) > 0),
  color_argb INTEGER NOT NULL CHECK(color_argb BETWEEN 0 AND 4294967295),
  display_order INTEGER NOT NULL CHECK(display_order >= 0),
  is_system_status INTEGER NOT NULL DEFAULT 0 CHECK(is_system_status IN (0,1)),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_attendance_active_code
  ON attendance_statuses(short_code) WHERE is_active = 1;
CREATE INDEX IF NOT EXISTS ix_attendance_status_order
  ON attendance_statuses(display_order,id);

CREATE TABLE IF NOT EXISTS attendance_status_history (
  id TEXT NOT NULL PRIMARY KEY,
  status_id TEXT NOT NULL REFERENCES attendance_statuses(id) ON DELETE RESTRICT,
  old_name TEXT NOT NULL,
  new_name TEXT NOT NULL,
  old_short_code TEXT NOT NULL,
  new_short_code TEXT NOT NULL,
  old_color_argb INTEGER NOT NULL,
  new_color_argb INTEGER NOT NULL,
  effective_date TEXT NOT NULL,
  changed_at TEXT NOT NULL,
  changed_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  audit_event_id TEXT REFERENCES audit_events(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS daily_attendance (
  id TEXT NOT NULL PRIMARY KEY,
  person_id TEXT NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
  attendance_date TEXT NOT NULL CHECK(length(attendance_date)=10),
  effective_site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  status_id TEXT NOT NULL REFERENCES attendance_statuses(id) ON DELETE RESTRICT,
  prepared_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  prepared_at TEXT NOT NULL,
  updated_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  updated_at TEXT NOT NULL,
  revision INTEGER NOT NULL DEFAULT 1 CHECK(revision >= 1),
  UNIQUE(person_id,attendance_date)
);
CREATE INDEX IF NOT EXISTS ix_attendance_site_date
  ON daily_attendance(effective_site_id,attendance_date,status_id);
CREATE INDEX IF NOT EXISTS ix_attendance_date_status
  ON daily_attendance(attendance_date,status_id);

CREATE TABLE IF NOT EXISTS attendance_revision_history (
  id TEXT NOT NULL PRIMARY KEY,
  attendance_id TEXT NOT NULL REFERENCES daily_attendance(id) ON DELETE RESTRICT,
  person_id TEXT NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
  attendance_date TEXT NOT NULL,
  old_status_id TEXT REFERENCES attendance_statuses(id) ON DELETE RESTRICT,
  new_status_id TEXT NOT NULL REFERENCES attendance_statuses(id) ON DELETE RESTRICT,
  previous_site_id TEXT REFERENCES sites(id) ON DELETE RESTRICT,
  effective_site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  changed_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  changed_at TEXT NOT NULL,
  audit_event_id TEXT REFERENCES audit_events(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS internal_transfers (
  id TEXT NOT NULL PRIMARY KEY,
  person_id TEXT NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
  from_site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  to_site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  effective_date TEXT NOT NULL,
  executed_at TEXT NOT NULL,
  executed_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  operation_group_id TEXT,
  CHECK(from_site_id <> to_site_id)
);
CREATE INDEX IF NOT EXISTS ix_internal_transfer_person_date ON internal_transfers(person_id,effective_date);

CREATE TABLE IF NOT EXISTS external_transfers (
  id TEXT NOT NULL PRIMARY KEY,
  person_id TEXT NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
  previous_site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  external_destination TEXT NOT NULL CHECK(length(trim(external_destination)) > 0),
  effective_date TEXT NOT NULL,
  executed_at TEXT NOT NULL,
  executed_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS ix_external_transfer_person_date ON external_transfers(person_id,effective_date);

CREATE TABLE IF NOT EXISTS dismissals (
  id TEXT NOT NULL PRIMARY KEY,
  person_id TEXT NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
  previous_site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  reason TEXT NOT NULL CHECK(length(trim(reason)) > 0),
  effective_date TEXT NOT NULL,
  executed_at TEXT NOT NULL,
  executed_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS ix_dismissals_person_date ON dismissals(person_id,effective_date);

CREATE TABLE IF NOT EXISTS attribute_definitions (
  id TEXT NOT NULL PRIMARY KEY,
  internal_key TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL CHECK(length(trim(display_name)) > 0),
  data_type TEXT NOT NULL CHECK(data_type IN ('TEXT','INTEGER','REAL','DATE','BOOLEAN')),
  display_order INTEGER NOT NULL CHECK(display_order >= 0),
  is_visible INTEGER NOT NULL DEFAULT 1 CHECK(is_visible IN (0,1)),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS person_attribute_values (
  person_id TEXT NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
  attribute_id TEXT NOT NULL REFERENCES attribute_definitions(id) ON DELETE RESTRICT,
  value TEXT,
  updated_at TEXT NOT NULL,
  PRIMARY KEY(person_id,attribute_id)
);

CREATE TABLE IF NOT EXISTS monthly_archives (
  id TEXT NOT NULL PRIMARY KEY,
  year INTEGER NOT NULL CHECK(year BETWEEN 1 AND 9999),
  month INTEGER NOT NULL CHECK(month BETWEEN 1 AND 12),
  archive_version INTEGER NOT NULL CHECK(archive_version >= 1),
  closed_at TEXT,
  closed_by_system INTEGER NOT NULL DEFAULT 0 CHECK(closed_by_system IN (0,1)),
  integrity_hash TEXT,
  is_sealed INTEGER NOT NULL DEFAULT 0 CHECK(is_sealed IN (0,1)),
  UNIQUE(year,month),
  CHECK(is_sealed = 0 OR (closed_at IS NOT NULL AND length(trim(integrity_hash)) > 0))
);
CREATE TABLE IF NOT EXISTS monthly_archive_persons (
  id TEXT NOT NULL PRIMARY KEY,
  archive_id TEXT NOT NULL REFERENCES monthly_archives(id) ON DELETE RESTRICT,
  person_id TEXT NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
  full_name_snapshot TEXT NOT NULL,
  personnel_number_snapshot TEXT NOT NULL,
  normalized_number_snapshot TEXT NOT NULL,
  lifecycle_snapshot TEXT NOT NULL,
  UNIQUE(archive_id,person_id)
);
CREATE TABLE IF NOT EXISTS monthly_archive_site_segments (
  id TEXT NOT NULL PRIMARY KEY,
  archive_person_id TEXT NOT NULL REFERENCES monthly_archive_persons(id) ON DELETE RESTRICT,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  site_name_snapshot TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to_exclusive TEXT,
  CHECK(effective_to_exclusive IS NULL OR effective_from < effective_to_exclusive),
  UNIQUE(archive_person_id,site_id,effective_from)
);
CREATE TABLE IF NOT EXISTS monthly_archive_days (
  id TEXT NOT NULL PRIMARY KEY,
  archive_person_id TEXT NOT NULL REFERENCES monthly_archive_persons(id) ON DELETE RESTRICT,
  attendance_date TEXT NOT NULL,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  site_name_snapshot TEXT NOT NULL,
  cell_kind TEXT NOT NULL CHECK(cell_kind IN ('ATTENDANCE','INTERNAL_TRANSFER_OUT','INTERNAL_TRANSFER_IN','EXTERNAL_TRANSFER','DISMISSED')),
  status_id TEXT REFERENCES attendance_statuses(id) ON DELETE RESTRICT,
  status_name_snapshot TEXT,
  status_code_snapshot TEXT,
  status_color_argb_snapshot INTEGER,
  marker_text TEXT,
  UNIQUE(archive_person_id,attendance_date,site_id,cell_kind),
  CHECK(cell_kind <> 'ATTENDANCE' OR (status_id IS NOT NULL AND status_name_snapshot IS NOT NULL AND status_code_snapshot IS NOT NULL))
);

-- Prevent post-seal mutation of the archive and all its snapshots.
CREATE TRIGGER IF NOT EXISTS trg_archive_sealed_update BEFORE UPDATE ON monthly_archives
WHEN OLD.is_sealed = 1 BEGIN SELECT RAISE(ABORT,'sealed archive cannot be updated'); END;
CREATE TRIGGER IF NOT EXISTS trg_archive_sealed_delete BEFORE DELETE ON monthly_archives
WHEN OLD.is_sealed = 1 BEGIN SELECT RAISE(ABORT,'sealed archive cannot be deleted'); END;

CREATE TRIGGER IF NOT EXISTS trg_archive_person_insert BEFORE INSERT ON monthly_archive_persons
WHEN (SELECT is_sealed FROM monthly_archives WHERE id=NEW.archive_id)=1
BEGIN SELECT RAISE(ABORT,'sealed archive is immutable'); END;
CREATE TRIGGER IF NOT EXISTS trg_archive_person_update BEFORE UPDATE ON monthly_archive_persons
WHEN (SELECT is_sealed FROM monthly_archives WHERE id=OLD.archive_id)=1 OR (SELECT is_sealed FROM monthly_archives WHERE id=NEW.archive_id)=1
BEGIN SELECT RAISE(ABORT,'sealed archive is immutable'); END;
CREATE TRIGGER IF NOT EXISTS trg_archive_person_delete BEFORE DELETE ON monthly_archive_persons
WHEN (SELECT is_sealed FROM monthly_archives WHERE id=OLD.archive_id)=1
BEGIN SELECT RAISE(ABORT,'sealed archive is immutable'); END;

CREATE TRIGGER IF NOT EXISTS trg_archive_segment_insert BEFORE INSERT ON monthly_archive_site_segments
WHEN (SELECT a.is_sealed FROM monthly_archives a JOIN monthly_archive_persons p ON a.id=p.archive_id WHERE p.id=NEW.archive_person_id)=1
BEGIN SELECT RAISE(ABORT,'sealed archive is immutable'); END;
CREATE TRIGGER IF NOT EXISTS trg_archive_segment_update BEFORE UPDATE ON monthly_archive_site_segments
WHEN (SELECT a.is_sealed FROM monthly_archives a JOIN monthly_archive_persons p ON a.id=p.archive_id WHERE p.id=OLD.archive_person_id)=1 OR (SELECT a.is_sealed FROM monthly_archives a JOIN monthly_archive_persons p ON a.id=p.archive_id WHERE p.id=NEW.archive_person_id)=1
BEGIN SELECT RAISE(ABORT,'sealed archive is immutable'); END;
CREATE TRIGGER IF NOT EXISTS trg_archive_segment_delete BEFORE DELETE ON monthly_archive_site_segments
WHEN (SELECT a.is_sealed FROM monthly_archives a JOIN monthly_archive_persons p ON a.id=p.archive_id WHERE p.id=OLD.archive_person_id)=1
BEGIN SELECT RAISE(ABORT,'sealed archive is immutable'); END;

CREATE TRIGGER IF NOT EXISTS trg_archive_day_insert BEFORE INSERT ON monthly_archive_days
WHEN (SELECT a.is_sealed FROM monthly_archives a JOIN monthly_archive_persons p ON a.id=p.archive_id WHERE p.id=NEW.archive_person_id)=1
BEGIN SELECT RAISE(ABORT,'sealed archive is immutable'); END;
CREATE TRIGGER IF NOT EXISTS trg_archive_day_update BEFORE UPDATE ON monthly_archive_days
WHEN (SELECT a.is_sealed FROM monthly_archives a JOIN monthly_archive_persons p ON a.id=p.archive_id WHERE p.id=OLD.archive_person_id)=1 OR (SELECT a.is_sealed FROM monthly_archives a JOIN monthly_archive_persons p ON a.id=p.archive_id WHERE p.id=NEW.archive_person_id)=1
BEGIN SELECT RAISE(ABORT,'sealed archive is immutable'); END;
CREATE TRIGGER IF NOT EXISTS trg_archive_day_delete BEFORE DELETE ON monthly_archive_days
WHEN (SELECT a.is_sealed FROM monthly_archives a JOIN monthly_archive_persons p ON a.id=p.archive_id WHERE p.id=OLD.archive_person_id)=1
BEGIN SELECT RAISE(ABORT,'sealed archive is immutable'); END;

CREATE TABLE IF NOT EXISTS authentication_events (
  id TEXT NOT NULL PRIMARY KEY,
  user_id TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  entered_username TEXT NOT NULL,
  event_type TEXT NOT NULL,
  occurred_at TEXT NOT NULL,
  outcome TEXT NOT NULL,
  details TEXT
);
CREATE INDEX IF NOT EXISTS ix_auth_events_user_time ON authentication_events(user_id,occurred_at);

CREATE TABLE IF NOT EXISTS import_batches (
  id TEXT NOT NULL PRIMARY KEY,
  source_file_name TEXT NOT NULL,
  import_mode TEXT NOT NULL CHECK(import_mode IN ('AUTOMATIC','SMART')),
  started_at TEXT NOT NULL,
  finished_at TEXT,
  imported_count INTEGER NOT NULL DEFAULT 0 CHECK(imported_count >= 0),
  rejected_count INTEGER NOT NULL DEFAULT 0 CHECK(rejected_count >= 0),
  executed_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT
);
CREATE TABLE IF NOT EXISTS import_rejected_rows (
  id TEXT NOT NULL PRIMARY KEY,
  import_batch_id TEXT NOT NULL REFERENCES import_batches(id) ON DELETE RESTRICT,
  sheet_name TEXT,
  row_number INTEGER NOT NULL CHECK(row_number > 0),
  raw_values TEXT,
  rejection_reason TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_rejected_rows_batch ON import_rejected_rows(import_batch_id,row_number);

CREATE TABLE IF NOT EXISTS export_history (
  id TEXT NOT NULL PRIMARY KEY,
  export_type TEXT NOT NULL,
  output_scope TEXT NOT NULL,
  output_path TEXT,
  item_count INTEGER NOT NULL DEFAULT 0 CHECK(item_count >= 0),
  executed_at TEXT NOT NULL,
  executed_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  result TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS backup_history (
  id TEXT NOT NULL PRIMARY KEY,
  backup_path TEXT NOT NULL,
  backup_type TEXT NOT NULL CHECK(backup_type IN ('MANUAL','SCHEDULED','BEFORE_RESTORE')),
  encrypted INTEGER NOT NULL CHECK(encrypted = 1),
  created_at TEXT NOT NULL,
  size_bytes INTEGER CHECK(size_bytes >= 0),
  integrity_hash TEXT,
  executed_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT,
  result TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS scheduled_backup_state (
  id TEXT NOT NULL PRIMARY KEY,
  scheduled_local_time TEXT NOT NULL,
  last_attempt_at TEXT,
  last_success_at TEXT,
  last_result TEXT,
  is_enabled INTEGER NOT NULL DEFAULT 1 CHECK(is_enabled IN (0,1))
);
CREATE TABLE IF NOT EXISTS application_settings (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL,
  data_type TEXT NOT NULL CHECK(data_type IN ('TEXT','INTEGER','REAL','BOOLEAN','JSON')),
  updated_at TEXT NOT NULL,
  updated_by TEXT REFERENCES app_users(id) ON DELETE RESTRICT
);
CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER NOT NULL PRIMARY KEY CHECK(version > 0),
  applied_at TEXT NOT NULL,
  checksum_sha256 TEXT NOT NULL,
  description TEXT NOT NULL
);


-- Canonical business numbers are validated by the DB, not just by the UI.
-- Arabic-Indic and Eastern Arabic/Persian numerals normalize to ASCII digits.
CREATE TRIGGER IF NOT EXISTS trg_person_number_normalized_insert
BEFORE INSERT ON persons
WHEN NEW.normalized_personnel_number <> REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(NEW.personnel_number,'٠','0'),'١','1'),'٢','2'),'٣','3'),'٤','4'),'٥','5'),'٦','6'),'٧','7'),'٨','8'),'٩','9'),'۰','0'),'۱','1'),'۲','2'),'۳','3'),'۴','4'),'۵','5'),'۶','6'),'۷','7'),'۸','8'),'۹','9'),' ',''),char(9),''),char(10),''),char(11),''),char(12),''),char(13),''),char(160),'')
BEGIN SELECT RAISE(ABORT,'incorrect normalized personnel number'); END;
CREATE TRIGGER IF NOT EXISTS trg_person_number_normalized_update
BEFORE UPDATE OF personnel_number,normalized_personnel_number ON persons
WHEN NEW.normalized_personnel_number <> REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(NEW.personnel_number,'٠','0'),'١','1'),'٢','2'),'٣','3'),'٤','4'),'٥','5'),'٦','6'),'٧','7'),'٨','8'),'٩','9'),'۰','0'),'۱','1'),'۲','2'),'۳','3'),'۴','4'),'۵','5'),'۶','6'),'۷','7'),'۸','8'),'۹','9'),' ',''),char(9),''),char(10),''),char(11),''),char(12),''),char(13),''),char(160),'')
BEGIN SELECT RAISE(ABORT,'incorrect normalized personnel number'); END;
CREATE TRIGGER IF NOT EXISTS trg_person_id_immutable BEFORE UPDATE OF id ON persons
WHEN NEW.id <> OLD.id
BEGIN SELECT RAISE(ABORT,'person_id cannot change'); END;

-- Protect foundational historical identities and application audit trails.
CREATE TRIGGER IF NOT EXISTS trg_persons_no_delete BEFORE DELETE ON persons
BEGIN SELECT RAISE(ABORT,'physical deletion of a person is prohibited'); END;
CREATE TRIGGER IF NOT EXISTS trg_sites_no_delete BEFORE DELETE ON sites
BEGIN SELECT RAISE(ABORT,'physical deletion of a site is prohibited'); END;
CREATE TRIGGER IF NOT EXISTS trg_statuses_no_delete BEFORE DELETE ON attendance_statuses
BEGIN SELECT RAISE(ABORT,'physical deletion of an attendance status is prohibited'); END;
CREATE TRIGGER IF NOT EXISTS trg_audit_no_update BEFORE UPDATE ON audit_events
BEGIN SELECT RAISE(ABORT,'audit events are append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_audit_no_delete BEFORE DELETE ON audit_events
BEGIN SELECT RAISE(ABORT,'audit events are append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_attendance_no_delete BEFORE DELETE ON daily_attendance
BEGIN SELECT RAISE(ABORT,'attendance deletion is prohibited; record a correction'); END;
CREATE TRIGGER IF NOT EXISTS trg_identity_history_no_update BEFORE UPDATE ON person_identity_history
BEGIN SELECT RAISE(ABORT,'identity history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_identity_history_no_delete BEFORE DELETE ON person_identity_history
BEGIN SELECT RAISE(ABORT,'identity history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_status_history_no_delete BEFORE DELETE ON attendance_status_history
BEGIN SELECT RAISE(ABORT,'status history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_status_history_no_update BEFORE UPDATE ON attendance_status_history
BEGIN SELECT RAISE(ABORT,'status history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_attendance_history_no_delete BEFORE DELETE ON attendance_revision_history
BEGIN SELECT RAISE(ABORT,'attendance revision history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_attendance_history_no_update BEFORE UPDATE ON attendance_revision_history
BEGIN SELECT RAISE(ABORT,'attendance revision history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_transfer_internal_no_delete BEFORE DELETE ON internal_transfers
BEGIN SELECT RAISE(ABORT,'transfer history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_transfer_internal_no_update BEFORE UPDATE ON internal_transfers
BEGIN SELECT RAISE(ABORT,'transfer history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_transfer_external_no_delete BEFORE DELETE ON external_transfers
BEGIN SELECT RAISE(ABORT,'transfer history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_transfer_external_no_update BEFORE UPDATE ON external_transfers
BEGIN SELECT RAISE(ABORT,'transfer history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_dismissals_no_delete BEFORE DELETE ON dismissals
BEGIN SELECT RAISE(ABORT,'dismissal history is append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_dismissals_no_update BEFORE UPDATE ON dismissals
BEGIN SELECT RAISE(ABORT,'dismissal history is append-only'); END;

CREATE TRIGGER IF NOT EXISTS trg_site_protect_default BEFORE UPDATE ON sites
WHEN OLD.is_system_site=1 AND (NEW.name <> OLD.name OR NEW.normalized_name <> OLD.normalized_name OR NEW.is_active <> 1 OR NEW.is_system_site <> 1)
BEGIN SELECT RAISE(ABORT,'protected system site cannot be changed'); END;
CREATE TRIGGER IF NOT EXISTS trg_site_protect_default_delete BEFORE DELETE ON sites
WHEN OLD.is_system_site=1
BEGIN SELECT RAISE(ABORT,'protected system site cannot be deleted'); END;
CREATE TRIGGER IF NOT EXISTS trg_site_single_system_insert BEFORE INSERT ON sites
WHEN NEW.is_system_site=1 AND EXISTS(SELECT 1 FROM sites WHERE is_system_site=1)
BEGIN SELECT RAISE(ABORT,'only one protected system site is allowed'); END;
CREATE TRIGGER IF NOT EXISTS trg_site_single_system_update BEFORE UPDATE ON sites
WHEN NEW.is_system_site=1 AND OLD.is_system_site=0
BEGIN SELECT RAISE(ABORT,'system site identity cannot be changed'); END;

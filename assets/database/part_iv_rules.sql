-- PART IV overlays PART III schema_v1.sql + seed_v1.sql.
-- Transitional schema extension only; future encrypted migrations must apply
-- this ruleset after v1. The tests use SQLite ':memory:' exclusively.
-- Date parameters are Gregorian civil dates in zero-padded YYYY-MM-DD format.
-- A repeated same-day transfer is rejected, rather than choosing arbitrary order.
CREATE UNIQUE INDEX IF NOT EXISTS ux_one_transfer_person_day
ON internal_transfers(person_id,effective_date);
CREATE UNIQUE INDEX IF NOT EXISTS ux_one_external_departure ON external_transfers(person_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_one_dismissal ON dismissals(person_id);

-- Read-only view; transfer markers may coexist with attendance on destination day.
CREATE VIEW IF NOT EXISTS v_monthly_cell_events AS
 SELECT person_id,effective_date AS day,from_site_id AS site_id,
        'INTERNAL_TRANSFER_OUT' AS kind,to_site_id AS related_site_id,
        NULL AS status_id FROM internal_transfers
 UNION ALL
 SELECT person_id,effective_date,to_site_id,'INTERNAL_TRANSFER_IN',from_site_id,NULL
 FROM internal_transfers
 UNION ALL
 SELECT person_id,attendance_date,effective_site_id,'ATTENDANCE',NULL,status_id
 FROM daily_attendance
 UNION ALL
 SELECT person_id,effective_date,previous_site_id,'EXTERNAL_TRANSFER',NULL,NULL
 FROM external_transfers
 UNION ALL
 SELECT person_id,effective_date,previous_site_id,'DISMISSED',NULL,NULL
 FROM dismissals;

-- Disallow any official daily record outside a valid site assignment, after
-- departure, or in an immutable completed month. The reference to current
-- lifecycle_status is intentionally ABSENT: historical date wins over today.
CREATE TRIGGER IF NOT EXISTS trg_p4_attendance_insert BEFORE INSERT ON daily_attendance
BEGIN
 SELECT RAISE(ABORT,'attendance requires eligible site on business date')
 WHERE NOT EXISTS (
  SELECT 1 FROM person_site_assignments a
  WHERE a.person_id=NEW.person_id AND a.site_id=NEW.effective_site_id
    AND a.effective_from<=NEW.attendance_date
    AND (a.effective_to_exclusive IS NULL OR NEW.attendance_date<a.effective_to_exclusive)
 ) OR EXISTS (SELECT 1 FROM external_transfers e WHERE e.person_id=NEW.person_id
                       AND e.effective_date<=NEW.attendance_date)
   OR EXISTS (SELECT 1 FROM dismissals d WHERE d.person_id=NEW.person_id
                       AND d.effective_date<=NEW.attendance_date);
 SELECT RAISE(ABORT,'sealed month cannot be prepared') WHERE EXISTS (
   SELECT 1 FROM monthly_archives m WHERE m.is_sealed=1
   AND m.year=CAST(substr(NEW.attendance_date,1,4) AS INTEGER)
   AND m.month=CAST(substr(NEW.attendance_date,6,2) AS INTEGER));
END;
CREATE TRIGGER IF NOT EXISTS trg_p4_attendance_update BEFORE UPDATE ON daily_attendance
BEGIN
 SELECT RAISE(ABORT,'attendance requires eligible site on business date')
 WHERE NOT EXISTS (
  SELECT 1 FROM person_site_assignments a
  WHERE a.person_id=NEW.person_id AND a.site_id=NEW.effective_site_id
    AND a.effective_from<=NEW.attendance_date
    AND (a.effective_to_exclusive IS NULL OR NEW.attendance_date<a.effective_to_exclusive)
 ) OR EXISTS (SELECT 1 FROM external_transfers e WHERE e.person_id=NEW.person_id
                       AND e.effective_date<=NEW.attendance_date)
   OR EXISTS (SELECT 1 FROM dismissals d WHERE d.person_id=NEW.person_id
                       AND d.effective_date<=NEW.attendance_date);
 SELECT RAISE(ABORT,'sealed attendance cannot be modified') WHERE EXISTS (
   SELECT 1 FROM monthly_archives m WHERE m.is_sealed=1
   AND ((m.year=CAST(substr(OLD.attendance_date,1,4) AS INTEGER)
      AND m.month=CAST(substr(OLD.attendance_date,6,2) AS INTEGER))
     OR (m.year=CAST(substr(NEW.attendance_date,1,4) AS INTEGER)
      AND m.month=CAST(substr(NEW.attendance_date,6,2) AS INTEGER))));
END;

CREATE TRIGGER IF NOT EXISTS trg_p4_transfer_insert BEFORE INSERT ON internal_transfers
BEGIN
 SELECT RAISE(ABORT,'transfer sites do not match assignment timeline') WHERE
   NOT EXISTS (SELECT 1 FROM person_site_assignments a WHERE a.person_id=NEW.person_id
     AND a.site_id=NEW.from_site_id
     AND a.effective_from<=date(NEW.effective_date,'-1 day')
     AND (a.effective_to_exclusive IS NULL OR date(NEW.effective_date,'-1 day')<a.effective_to_exclusive))
   OR NOT EXISTS (SELECT 1 FROM person_site_assignments a WHERE a.person_id=NEW.person_id
     AND a.site_id=NEW.to_site_id AND a.effective_from<=NEW.effective_date
     AND (a.effective_to_exclusive IS NULL OR NEW.effective_date<a.effective_to_exclusive));
 SELECT RAISE(ABORT,'transfer day attendance must belong to destination') WHERE EXISTS (
  SELECT 1 FROM daily_attendance d WHERE d.person_id=NEW.person_id
   AND d.attendance_date=NEW.effective_date
   AND d.effective_site_id<>NEW.to_site_id);
 SELECT RAISE(ABORT,'transfer after departure') WHERE
  EXISTS (SELECT 1 FROM external_transfers e WHERE e.person_id=NEW.person_id AND e.effective_date<=NEW.effective_date)
  OR EXISTS (SELECT 1 FROM dismissals d WHERE d.person_id=NEW.person_id AND d.effective_date<=NEW.effective_date);
 SELECT RAISE(ABORT,'cannot transfer in sealed month') WHERE EXISTS (
   SELECT 1 FROM monthly_archives m WHERE m.is_sealed=1
   AND m.year=CAST(substr(NEW.effective_date,1,4) AS INTEGER)
   AND m.month=CAST(substr(NEW.effective_date,6,2) AS INTEGER));
END;

CREATE TRIGGER IF NOT EXISTS trg_p4_external_insert BEFORE INSERT ON external_transfers
BEGIN
 SELECT RAISE(ABORT,'conflicting departure') WHERE EXISTS
 (SELECT 1 FROM dismissals d WHERE d.person_id=NEW.person_id);
 SELECT RAISE(ABORT,'historical attendance/transfer would be invalidated') WHERE EXISTS
 (SELECT 1 FROM daily_attendance a WHERE a.person_id=NEW.person_id AND a.attendance_date>=NEW.effective_date)
 OR EXISTS (SELECT 1 FROM internal_transfers t WHERE t.person_id=NEW.person_id AND t.effective_date>=NEW.effective_date);
 SELECT RAISE(ABORT,'wrong previous site') WHERE NOT EXISTS (
  SELECT 1 FROM person_site_assignments a WHERE a.person_id=NEW.person_id
   AND a.site_id=NEW.previous_site_id AND a.effective_from<=date(NEW.effective_date,'-1 day')
   AND (a.effective_to_exclusive IS NULL OR date(NEW.effective_date,'-1 day')<a.effective_to_exclusive));
 SELECT RAISE(ABORT,'departure conflicts with sealed month') WHERE EXISTS
 (SELECT 1 FROM monthly_archives m WHERE m.is_sealed=1
  AND (m.year>CAST(substr(NEW.effective_date,1,4) AS INTEGER)
   OR (m.year=CAST(substr(NEW.effective_date,1,4) AS INTEGER)
    AND m.month>=CAST(substr(NEW.effective_date,6,2) AS INTEGER))));
END;

CREATE TRIGGER IF NOT EXISTS trg_p4_dismissal_insert BEFORE INSERT ON dismissals
BEGIN
 SELECT RAISE(ABORT,'conflicting departure') WHERE EXISTS
 (SELECT 1 FROM external_transfers e WHERE e.person_id=NEW.person_id);
 SELECT RAISE(ABORT,'historical attendance/transfer would be invalidated') WHERE EXISTS
 (SELECT 1 FROM daily_attendance a WHERE a.person_id=NEW.person_id AND a.attendance_date>=NEW.effective_date)
 OR EXISTS (SELECT 1 FROM internal_transfers t WHERE t.person_id=NEW.person_id AND t.effective_date>=NEW.effective_date);
 SELECT RAISE(ABORT,'wrong previous site') WHERE NOT EXISTS (
  SELECT 1 FROM person_site_assignments a WHERE a.person_id=NEW.person_id
   AND a.site_id=NEW.previous_site_id AND a.effective_from<=date(NEW.effective_date,'-1 day')
   AND (a.effective_to_exclusive IS NULL OR date(NEW.effective_date,'-1 day')<a.effective_to_exclusive));
 SELECT RAISE(ABORT,'departure conflicts with sealed month') WHERE EXISTS
 (SELECT 1 FROM monthly_archives m WHERE m.is_sealed=1
  AND (m.year>CAST(substr(NEW.effective_date,1,4) AS INTEGER)
   OR (m.year=CAST(substr(NEW.effective_date,1,4) AS INTEGER)
    AND m.month>=CAST(substr(NEW.effective_date,6,2) AS INTEGER))));
END;

-- Disallow changing lifecycle status independently of the formal event.
CREATE TRIGGER IF NOT EXISTS trg_p4_lifecycle_before_update
BEFORE UPDATE OF lifecycle_status ON persons
WHEN NEW.lifecycle_status<>OLD.lifecycle_status
BEGIN
 SELECT RAISE(ABORT,'personnel lifecycle change requires official event')
 WHERE OLD.lifecycle_status<>'ACTIVE'
 OR (NEW.lifecycle_status='DISMISSED' AND NOT EXISTS
     (SELECT 1 FROM dismissals d WHERE d.person_id=NEW.id))
 OR (NEW.lifecycle_status='EXTERNALLY_TRANSFERRED' AND NOT EXISTS
     (SELECT 1 FROM external_transfers e WHERE e.person_id=NEW.id))
 OR NEW.lifecycle_status='ACTIVE';
END;

-- Assignment history is never physically deleted. Historical months cannot
-- be reassigned; ending an old open interval *after* the sealed month is safe.
CREATE TRIGGER IF NOT EXISTS trg_p4_assignment_no_delete
BEFORE DELETE ON person_site_assignments
BEGIN SELECT RAISE(ABORT,'site assignment history cannot be deleted'); END;
CREATE TRIGGER IF NOT EXISTS trg_p4_assignment_insert_sealed
BEFORE INSERT ON person_site_assignments
WHEN EXISTS (SELECT 1 FROM monthly_archives m WHERE m.is_sealed=1
 AND NEW.effective_from<date(printf('%04d-%02d-01',m.year,m.month),'+1 month')
 AND (NEW.effective_to_exclusive IS NULL OR
 NEW.effective_to_exclusive>printf('%04d-%02d-01',m.year,m.month)))
BEGIN SELECT RAISE(ABORT,'cannot insert assignment into sealed month'); END;
CREATE TRIGGER IF NOT EXISTS trg_p4_assignment_update_sealed
BEFORE UPDATE ON person_site_assignments
WHEN EXISTS (
 SELECT 1 FROM monthly_archives m WHERE m.is_sealed=1 AND (
  ((NEW.effective_from<>OLD.effective_from OR NEW.site_id<>OLD.site_id)
   AND (OLD.effective_from<date(printf('%04d-%02d-01',m.year,m.month),'+1 month')
    OR NEW.effective_from<date(printf('%04d-%02d-01',m.year,m.month),'+1 month')))
  OR (OLD.effective_to_exclusive IS NOT NEW.effective_to_exclusive
   AND (COALESCE(OLD.effective_to_exclusive,'9999-12-31') <
          date(printf('%04d-%02d-01',m.year,m.month),'+1 month')
    OR COALESCE(NEW.effective_to_exclusive,'9999-12-31') <
          date(printf('%04d-%02d-01',m.year,m.month),'+1 month'))
   AND (OLD.effective_from<date(printf('%04d-%02d-01',m.year,m.month),'+1 month')
    OR NEW.effective_from<date(printf('%04d-%02d-01',m.year,m.month),'+1 month')))
 ))
BEGIN SELECT RAISE(ABORT,'historical assignment in sealed month cannot change'); END;

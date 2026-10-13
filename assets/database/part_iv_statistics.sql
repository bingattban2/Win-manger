-- Parameterized query contract; bind :report_date, optionally :site_id (NULL=all).
-- NEVER filter historical force by persons.lifecycle_status (current state).
WITH eligible AS (
 SELECT DISTINCT p.id AS person_id, a.site_id
 FROM persons p
 JOIN person_site_assignments a ON a.person_id=p.id
 WHERE a.effective_from<=:report_date
  AND (a.effective_to_exclusive IS NULL OR :report_date<a.effective_to_exclusive)
  AND (:site_id IS NULL OR a.site_id=:site_id)
  AND NOT EXISTS(SELECT 1 FROM external_transfers e
   WHERE e.person_id=p.id AND e.effective_date<=:report_date)
  AND NOT EXISTS(SELECT 1 FROM dismissals d
   WHERE d.person_id=p.id AND d.effective_date<=:report_date)
), status_counts AS (
 SELECT e.person_id, d.status_id
 FROM eligible e LEFT JOIN daily_attendance d
  ON d.person_id=e.person_id AND d.attendance_date=:report_date
)
SELECT COALESCE(status_id,'__UNPREPARED__') AS status_id, COUNT(*) AS count
FROM status_counts GROUP BY COALESCE(status_id,'__UNPREPARED__');

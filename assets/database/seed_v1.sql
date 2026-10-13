-- System reference data only. No user credentials and no real personnel data.
-- Fixed IDs are reserved forever; migrations must never reassign them.
INSERT INTO sites
  (id,name,normalized_name,is_system_site,is_active,created_at,updated_at)
SELECT '00000000-0000-4000-8000-000000000001','غير محدد','غير محدد',1,1,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z'
WHERE NOT EXISTS (SELECT 1 FROM sites WHERE id='00000000-0000-4000-8000-000000000001');

INSERT OR IGNORE INTO attendance_statuses
  (id,name,short_code,color_argb,display_order,is_system_status,is_active,created_at,updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000011','موجود','م',0xFF81D4FA,0,1,1,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000012','إجازة','ج',0xFF4CAF50,1,1,1,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000013','غياب','غ',0xFFF44336,2,1,1,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000014','إذن','إ',0xFFFFEB3B,3,1,1,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z');

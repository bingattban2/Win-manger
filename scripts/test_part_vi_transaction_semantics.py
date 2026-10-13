"""Real SQLite transaction proof tests (no persistence or Windows drivers)."""
import hashlib
import json
from pathlib import Path
import sqlite3
import unittest

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "assets/database"
DATE = "2026-10-13"
TIME = "2026-10-13T19:00:00Z"
ACTOR = "00000000-0000-4000-8000-000000000099"


class TransactionProofTests(unittest.TestCase):
    def setUp(self):
        self.connection = sqlite3.connect(":memory:")
        self.connection.isolation_level = None  # BEGIN/ROLLBACK are explicit.
        for sql in ("schema_v1.sql", "seed_v1.sql", "part_iv_rules.sql", "part_v_authorization.sql"):
            self.connection.executescript((DB / sql).read_text(encoding="utf-8"))
        self.connection.execute("INSERT INTO sites(id,name,normalized_name,is_system_site,is_active,created_at,updated_at) VALUES(?,?,?,0,1,?,?)",
                                ("site-new", "الموقع الأول", "الموقع الأول", TIME, TIME))

    def tearDown(self):
        self.connection.close()

    def rename(self, *, audit_enabled=True, cause_history_failure=False):
        db = self.connection
        db.execute("BEGIN IMMEDIATE")
        try:
            current = db.execute("SELECT name,updated_at,is_system_site FROM sites WHERE id='site-new'").fetchone()
            if not current or current[2]:
                raise ValueError("Site not renameable")
            db.execute("UPDATE sites SET name=?,normalized_name=?,updated_at=? WHERE id=? AND updated_at=?",
                       ("الموقع الثاني", "الموقع الثاني", "2026-10-13T19:00:01Z", "site-new", current[1]))
            if db.execute("SELECT changes()").fetchone()[0] != 1:
                raise ValueError("Stale record")
            if cause_history_failure:
                # Mandatory NOT NULL constraint proves history failure reverts update.
                db.execute("INSERT INTO site_name_history(id,site_id,old_name,new_name,effective_date,changed_at) VALUES('h-1','site-new',NULL,'x',?,?)", (DATE, TIME))
            else:
                db.execute("INSERT INTO site_name_history(id,site_id,old_name,new_name,effective_date,changed_at,changed_by) VALUES('h-1','site-new',?,?,?, ?,?)",
                           (current[0], "الموقع الثاني", DATE, TIME, ACTOR))
            if audit_enabled:
                before = json.dumps({"name": current[0]}, ensure_ascii=False)
                after = json.dumps({"name": "الموقع الثاني"}, ensure_ascii=False)
                digest = hashlib.sha256((before + after).encode()).hexdigest()
                db.execute("INSERT INTO audit_events(id,operation_type,target_type,target_id,target_display_name,actor_user_id,executed_at,old_values,new_values,result,event_hash) VALUES(?,?,?,?,?,?,?,?,?,'SUCCESS',?)",
                           ("a-1", "SITE_RENAME", "SITE", "site-new", "الموقع الثاني", ACTOR, TIME, before, after, digest))
            else:
                # NULL event_hash violates audit NOT NULL and rolls back all writes.
                db.execute("INSERT INTO audit_events(id,operation_type,target_type,target_display_name,executed_at,result,event_hash) VALUES('a-1','SITE_RENAME','SITE','x',?,'SUCCESS',NULL)", (TIME,))
            db.execute("COMMIT")
        except BaseException:
            db.execute("ROLLBACK")
            raise

    def assert_unchanged(self):
        db = self.connection
        self.assertEqual(db.execute("SELECT name FROM sites WHERE id='site-new'").fetchone()[0], "الموقع الأول")
        self.assertEqual(db.execute("SELECT COUNT(*) FROM site_name_history WHERE site_id='site-new'").fetchone()[0], 0)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM audit_events WHERE target_id='site-new'").fetchone()[0], 0)

    def test_01_sqlite_commit_atomic_site_history_audit(self):
        self.rename()
        db = self.connection
        self.assertEqual(db.execute("SELECT name FROM sites WHERE id='site-new'").fetchone()[0], "الموقع الثاني")
        self.assertEqual(db.execute("SELECT COUNT(*) FROM site_name_history WHERE site_id='site-new'").fetchone()[0], 1)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM audit_events WHERE target_id='site-new'").fetchone()[0], 1)

    def test_02_history_failure_rollback_everything(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.rename(cause_history_failure=True)
        self.assert_unchanged()

    def test_03_audit_failure_rollback_everything(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.rename(audit_enabled=False)
        self.assert_unchanged()

    def test_04_protect_system_site(self):
        site_id = self.connection.execute("SELECT id FROM sites WHERE is_system_site=1 LIMIT 1").fetchone()[0]
        with self.assertRaises(sqlite3.IntegrityError):
            self.connection.execute("UPDATE sites SET name='غير معروف' WHERE id=?", (site_id,))


if __name__ == "__main__":
    unittest.main()

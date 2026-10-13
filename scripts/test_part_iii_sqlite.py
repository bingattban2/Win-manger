"""Executable PART III contract tests using isolated in-memory SQLite only.

These do NOT create a plaintext production database or user accounts.
Runtime storage is intentionally held behind the future encrypted backend.
"""
from __future__ import annotations

import re
import sqlite3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = (ROOT / 'assets/database/schema_v1.sql').read_text(encoding='utf-8')
SEED = (ROOT / 'assets/database/seed_v1.sql').read_text(encoding='utf-8')
NOW = '2026-10-13T17:00:00Z'
SITE_SYSTEM = '00000000-0000-4000-8000-000000000001'
PRESENT = '00000000-0000-4000-8000-000000000011'

TABLES = {
    'persons', 'personnel_number_registry', 'person_identity_history', 'sites', 'site_name_history',
    'person_site_assignments', 'attendance_statuses',
    'attendance_status_history', 'daily_attendance',
    'attendance_revision_history', 'internal_transfers', 'external_transfers',
    'dismissals', 'attribute_definitions', 'person_attribute_values',
    'monthly_archives', 'monthly_archive_persons', 'monthly_archive_days',
    'app_users', 'audit_events', 'authentication_events', 'import_batches',
    'import_rejected_rows', 'export_history', 'backup_history',
    'scheduled_backup_state', 'application_settings', 'schema_migrations',
    'monthly_archive_site_segments',
}

REQUIRED_COLUMNS = {
    'persons': ('id','personnel_number','normalized_personnel_number','full_name',
                'normalized_name','lifecycle_status','created_at','created_by',
                'updated_at','updated_by'),
    'person_identity_history': ('id','person_id','old_name','new_name',
                'old_personnel_number','new_personnel_number','changed_at',
                'changed_by','audit_event_id'),
    'sites': ('id','name','normalized_name','is_system_site','is_active',
              'created_at','updated_at'),
    'site_name_history': ('id','site_id','old_name','new_name','effective_date',
                         'changed_at','changed_by'),
    'person_site_assignments': ('id','person_id','site_id','effective_from',
              'effective_to_exclusive','assignment_reason','created_at','created_by'),
    'attendance_statuses': ('id','name','short_code','color_argb','display_order',
              'is_system_status','is_active','created_at','updated_at'),
    'daily_attendance': ('id','person_id','attendance_date','effective_site_id',
              'status_id','prepared_by','prepared_at','updated_by','updated_at','revision'),
    'internal_transfers': ('id','person_id','from_site_id','to_site_id',
              'effective_date','executed_at','executed_by','operation_group_id'),
    'external_transfers': ('id','person_id','previous_site_id',
              'external_destination','effective_date','executed_at','executed_by'),
    'dismissals': ('id','person_id','previous_site_id','reason','effective_date',
                   'executed_at','executed_by'),
    'attribute_definitions': ('id','internal_key','display_name','data_type',
              'display_order','is_visible','is_active','created_at'),
    'person_attribute_values': ('person_id','attribute_id','value','updated_at'),
    'monthly_archives': ('id','year','month','archive_version','closed_at',
              'closed_by_system','integrity_hash','is_sealed'),
    'app_users': ('id','username','normalized_username','person_id','role',
              'password_hash','is_active','is_deleted','created_by','created_at',
              'updated_at'),
    'audit_events': ('id','operation_type','target_type','target_id',
              'target_display_name','actor_user_id','executed_at','effective_date',
              'old_values','new_values','operation_group_id','result','previous_hash',
              'event_hash'),
}


class PartIIISqliteContractTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.execute('PRAGMA foreign_keys=ON')
        self.db.executescript(SCHEMA)
        self.db.executescript(SEED)

    def tearDown(self):
        self.db.close()

    def add_person(self, number='0012', normalized='0012', person_id='p1'):
        self.db.execute('''INSERT INTO persons
          (id,personnel_number,normalized_personnel_number,full_name,
           normalized_name,lifecycle_status,created_at,updated_at)
          VALUES (?,?,?,'أحمد سالم','احمد سالم','ACTIVE',?,?)''',
          (person_id, number, normalized, NOW, NOW))

    def add_site(self, site_id='s1', name='موقع أ'):
        self.db.execute('''INSERT INTO sites
          (id,name,normalized_name,is_system_site,is_active,created_at,updated_at)
          VALUES (?,?,?,0,1,?,?)''', (site_id, name, name, NOW, NOW))

    def test_01_all_required_tables_exist(self):
        actual = {r[0] for r in self.db.execute("""
          SELECT name FROM sqlite_master WHERE type='table'
          AND name NOT LIKE 'sqlite_%'""")}
        self.assertEqual(actual, TABLES)
        self.assertEqual(len(actual), 29)

    def test_02_every_specified_required_column_exists(self):
        for table, columns in REQUIRED_COLUMNS.items():
            actual = {r[1] for r in self.db.execute(f'PRAGMA table_info({table})')}
            self.assertTrue(set(columns).issubset(actual), table)

    def test_03_foreign_keys_are_enabled_and_reject_orphans(self):
        self.assertEqual(self.db.execute('PRAGMA foreign_keys').fetchone()[0], 1)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO person_site_assignments
                (id,person_id,site_id,effective_from,assignment_reason,created_at)
                VALUES ('a1','missing',?,'2026-10-01','IMPORT',?)''',
                (SITE_SYSTEM, NOW))

    def test_04_default_site_and_colors(self):
        system = self.db.execute('SELECT name,is_system_site,is_active FROM sites WHERE id=?',
                                 (SITE_SYSTEM,)).fetchone()
        self.assertEqual(system, ('غير محدد',1,1))
        self.assertEqual(self.db.execute('''SELECT name,short_code,color_argb FROM
          attendance_statuses ORDER BY display_order''').fetchall(), [
              ('موجود','م',0xFF81D4FA), ('إجازة','ج',0xFF4CAF50),
              ('غياب','غ',0xFFF44336), ('إذن','إ',0xFFFFEB3B)])

    def test_05_seed_is_idempotent(self):
        self.db.executescript(SEED)
        self.assertEqual(self.db.execute('SELECT count(*) FROM sites').fetchone()[0], 1)
        self.assertEqual(self.db.execute('SELECT count(*) FROM attendance_statuses').fetchone()[0], 4)

    def test_06_system_site_cannot_be_renamed_or_deactivated(self):
        for sql in (
            "UPDATE sites SET name='غير مصنف' WHERE is_system_site=1",
            "UPDATE sites SET is_active=0 WHERE is_system_site=1",
            "UPDATE sites SET normalized_name='other' WHERE is_system_site=1",
            "DELETE FROM sites WHERE is_system_site=1",
        ):
            with self.subTest(sql=sql), self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(sql)

    def test_07_personnel_number_is_text_and_preserves_zeroes(self):
        self.add_person()
        value = self.db.execute('''SELECT personnel_number,normalized_personnel_number,
          typeof(personnel_number) FROM persons''').fetchone()
        self.assertEqual(value, ('0012','0012','text'))

    def test_08_normalization_is_enforced_not_just_stored(self):
        self.add_person(number='٠٠١٢', normalized='0012')
        with self.assertRaises(sqlite3.IntegrityError):
            self.add_person(number='۰۰۱۲',normalized='0012',person_id='p2')
        with self.assertRaises(sqlite3.IntegrityError):
            self.add_person(number='٠٠١٢',normalized='wrong',person_id='p3')

    def test_09_retired_person_numbers_remain_globally_reserved(self):
        self.add_person()
        self.db.execute("UPDATE persons SET lifecycle_status='DISMISSED' WHERE id='p1'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.add_person(number='٠٠١٢', normalized='0012', person_id='p2')
        self.db.execute("UPDATE persons SET lifecycle_status='EXTERNALLY_TRANSFERRED' WHERE id='p1'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.add_person(number='0012',normalized='0012',person_id='p3')

    def test_10a_corrected_old_business_numbers_stay_reserved(self):
        self.add_person()
        self.db.execute("""UPDATE persons SET personnel_number='0013',
          normalized_personnel_number='0013',updated_at=? WHERE id='p1'""",(NOW,))
        actual = dict(self.db.execute("""SELECT normalized_number,person_id
          FROM personnel_number_registry""").fetchall())
        self.assertEqual(actual, {'0012':'p1','0013':'p1'})
        with self.assertRaises(sqlite3.IntegrityError):
            self.add_person('٠٠١٢','0012','p2')
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("DELETE FROM personnel_number_registry WHERE normalized_number='0012'")
        # A correction back to a number previously held by the SAME person is valid.
        self.db.execute("""UPDATE persons SET personnel_number='0012',
          normalized_personnel_number='0012' WHERE id='p1'""")

    def test_10_person_id_is_immutable_and_person_cannot_be_deleted(self):
        self.add_person()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE persons SET id='p2' WHERE id='p1'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("DELETE FROM persons WHERE id='p1'")

    def test_11_assignment_intervals_do_not_overlap(self):
        self.add_person()
        self.add_site()
        self.db.execute('''INSERT INTO person_site_assignments
          (id,person_id,site_id,effective_from,effective_to_exclusive,assignment_reason,created_at)
          VALUES ('a1','p1','s1','2026-10-01','2026-10-10','IMPORT',?)''',(NOW,))
        # Adjacent half-open intervals are valid.
        self.db.execute('''INSERT INTO person_site_assignments
          (id,person_id,site_id,effective_from,assignment_reason,created_at)
          VALUES ('a2','p1',?,'2026-10-10','TRANSFER',?)''',(SITE_SYSTEM,NOW))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO person_site_assignments
              (id,person_id,site_id,effective_from,assignment_reason,created_at)
              VALUES ('a3','p1','s1','2026-10-05','TRANSFER',?)''',(NOW,))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE person_site_assignments SET effective_from='2026-10-09' WHERE id='a2'")

    def test_12_one_attendance_status_per_person_per_date(self):
        self.add_person()
        template = '''INSERT INTO daily_attendance
            (id,person_id,attendance_date,effective_site_id,status_id,
             prepared_at,updated_at,revision)
            VALUES (?, 'p1','2026-10-13',?,?,?, ?,1)'''
        self.db.execute(template,('d1',SITE_SYSTEM,PRESENT,NOW,NOW))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(template,('d2',SITE_SYSTEM,
                '00000000-0000-4000-8000-000000000012',NOW,NOW))

    def test_13_dynamic_attribute_value_is_unique_per_person(self):
        self.add_person()
        self.db.execute('''INSERT INTO attribute_definitions
          (id,internal_key,display_name,data_type,display_order,created_at)
          VALUES ('custom1','group_name','الفصيلة','TEXT',1,?)''',(NOW,))
        self.db.execute("""INSERT INTO person_attribute_values VALUES
          ('p1','custom1','أ',?)""",(NOW,))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("""INSERT INTO person_attribute_values VALUES
              ('p1','custom1','ب',?)""",(NOW,))

    def test_14_same_archived_month_cannot_be_created_twice(self):
        self.db.execute("""INSERT INTO monthly_archives
          (id,year,month,archive_version) VALUES ('month1',2026,9,1)""")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("""INSERT INTO monthly_archives
              (id,year,month,archive_version) VALUES ('month2',2026,9,1)""")

    def test_15_sealed_archives_and_children_are_immutable(self):
        self.add_person()
        self.db.execute("""INSERT INTO monthly_archives
          (id,year,month,archive_version) VALUES ('month1',2026,9,1)""")
        self.db.execute("""INSERT INTO monthly_archive_persons
          (id,archive_id,person_id,full_name_snapshot,personnel_number_snapshot,
          normalized_number_snapshot,lifecycle_snapshot)
          VALUES ('snap1','month1','p1','أحمد سالم','0012','0012','ACTIVE')""")
        self.db.execute("""INSERT INTO monthly_archive_site_segments
          (id,archive_person_id,site_id,site_name_snapshot,effective_from)
          VALUES ('seg1','snap1',?,'غير محدد','2026-09-01')""",(SITE_SYSTEM,))
        self.db.execute("""INSERT INTO monthly_archive_days
          (id,archive_person_id,attendance_date,site_id,site_name_snapshot,
           cell_kind,status_id,status_name_snapshot,status_code_snapshot)
          VALUES ('day1','snap1','2026-09-01',?,'غير محدد','ATTENDANCE',?,
           'موجود','م')""",(SITE_SYSTEM,PRESENT))
        self.db.execute("""UPDATE monthly_archives SET is_sealed=1,
          closed_at=?,integrity_hash='hash-123' WHERE id='month1'""",(NOW,))
        attempts = [
          "UPDATE monthly_archives SET is_sealed=0 WHERE id='month1'",
          "DELETE FROM monthly_archives WHERE id='month1'",
          "UPDATE monthly_archive_persons SET full_name_snapshot='x' WHERE id='snap1'",
          "DELETE FROM monthly_archive_persons WHERE id='snap1'",
          "UPDATE monthly_archive_site_segments SET site_name_snapshot='x' WHERE id='seg1'",
          "DELETE FROM monthly_archive_site_segments WHERE id='seg1'",
          "UPDATE monthly_archive_days SET status_name_snapshot='x' WHERE id='day1'",
          "DELETE FROM monthly_archive_days WHERE id='day1'",
        ]
        for sql in attempts:
            with self.subTest(sql=sql), self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(sql)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("""INSERT INTO monthly_archive_days
              (id,archive_person_id,attendance_date,site_id,site_name_snapshot,cell_kind)
              VALUES ('day2','snap1','2026-09-02',?,'غير محدد','DISMISSED')""",(SITE_SYSTEM,))

    def test_16_append_only_audit_records_cannot_be_tampered_with(self):
        self.db.execute("""INSERT INTO audit_events
          (id,operation_type,target_type,target_display_name,executed_at,result,event_hash)
          VALUES ('log1','IMPORT','PERSON','test',?,'SUCCESS','abcdef')""",(NOW,))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE audit_events SET result='FAILURE' WHERE id='log1'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("DELETE FROM audit_events WHERE id='log1'")

    def test_17_nonfoundational_accounts_require_person_link(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("""INSERT INTO app_users
              (id,username,normalized_username,role,password_hash,created_at,updated_at)
              VALUES ('u1','manager','manager','SUPERVISOR','HASH',?,?)""",(NOW,NOW))
        # Foundational administrator can be unassociated. No real credentials are seeded.
        self.db.execute("""INSERT INTO app_users
          (id,username,normalized_username,role,password_hash,created_at,updated_at)
          VALUES ('u2','placeholder','placeholder','GENERAL_ADMIN','HASH',?,?)""",(NOW,NOW))

    def test_18_rollback_restores_atomic_batch_state(self):
        self.add_person()
        self.db.commit()
        with self.assertRaises(sqlite3.IntegrityError):
            with self.db:
                self.add_person('0013','0013','p2')
                self.add_person('0012','0012','p3')
        self.assertEqual(self.db.execute('SELECT count(*) FROM persons').fetchone()[0],1)

    def test_19_integrity_check(self):
        self.assertEqual(self.db.execute('PRAGMA integrity_check').fetchone()[0], 'ok')
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])

    def test_20_catalog_and_canonical_sql_inventory_are_identical(self):
        dart = (ROOT / 'lib/core/domain/schema_catalog.dart').read_text(encoding='utf-8')
        block = dart.split('tableNames = <String>[',1)[1].split('];',1)[0]
        actual = set(re.findall(r"'([a-z_]+)'", block))
        self.assertEqual(actual, TABLES)

    def test_21_no_initial_admin_secrets_or_personnel_records_in_seed(self):
        self.assertEqual(self.db.execute('SELECT count(*) FROM app_users').fetchone()[0], 0)
        self.assertEqual(self.db.execute('SELECT count(*) FROM persons').fetchone()[0], 0)
        self.assertNotIn('INSERT INTO app_users', SCHEMA + SEED)


if __name__ == '__main__':
    unittest.main()

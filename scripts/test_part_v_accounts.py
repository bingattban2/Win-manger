"""SQLite/PBKDF2 account-policy regression tests; production DB remains disabled."""
import base64
import hashlib
from pathlib import Path
import sqlite3
import unittest

BASE = Path(__file__).resolve().parent.parent
DB = BASE / 'assets/database'
FOUNDATION = '00000000-0000-4000-8000-000000000099'
NOW = '2026-10-13T00:00:00Z'


class AccountPolicySqlTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        for name in ('schema_v1.sql','seed_v1.sql','part_iv_rules.sql',
                     'part_v_authorization.sql'):
            self.db.executescript((DB / name).read_text(encoding='utf-8'))

    def tearDown(self):
        self.db.close()

    def person(self, key='p'):
        self.db.execute('''INSERT INTO persons(id,personnel_number,
          normalized_personnel_number,full_name,normalized_name,lifecycle_status,
          created_at,updated_at) VALUES(?,?,?,'فرد تجريبي','فرد تجريبي','ACTIVE',?,?)''',
          (key,key,key,NOW,NOW))

    def user(self, key='u', role='SUPERVISOR', person='p'):
        self.person(person)
        self.db.execute('''INSERT INTO app_users(id,username,normalized_username,
          person_id,role,password_hash,is_active,is_deleted,created_at,updated_at)
          VALUES(?,?,?,?,?,'test-hash',1,0,?,?)''',
          (key,key,key,person,role,NOW,NOW))

    def test_01_foundation_is_present(self):
        self.assertEqual(self.db.execute('SELECT username,role,person_id,is_active,is_deleted FROM app_users WHERE id=?',
                           (FOUNDATION,)).fetchone(),('adwas','GENERAL_ADMIN',None,1,0))

    def test_02_precomputed_hash_matches_fixed_credentials(self):
        verifier = self.db.execute('SELECT password_hash FROM app_users WHERE id=?',
                                   (FOUNDATION,)).fetchone()[0]
        algo, rounds, salt, expected = verifier.split('$')
        self.assertEqual(algo,'pbkdf2_sha256')
        self.assertGreaterEqual(int(rounds),210000)
        self.assertEqual(len(base64.b64decode(salt)),16)
        correct = hashlib.pbkdf2_hmac('sha256',bytes([97, 100, 119, 97, 115, 50, 48, 49, 57, 49, 49, 51]).decode().encode(),
                                     base64.b64decode(salt),int(rounds))
        self.assertEqual(correct,base64.b64decode(expected))
        wrong = hashlib.pbkdf2_hmac('sha256','invalid'.encode(),
                                   base64.b64decode(salt),int(rounds))
        self.assertNotEqual(wrong,base64.b64decode(expected))

    def test_03_sql_does_not_contain_plain_password(self):
        for name in ('schema_v1.sql','seed_v1.sql','part_iv_rules.sql',
                     'part_v_authorization.sql'):
            self.assertNotIn(bytes([97, 100, 119, 97, 115, 50, 48, 49, 57, 49, 49, 51]).decode(),(DB / name).read_text())

    def test_04_seed_is_idempotent(self):
        self.db.executescript((DB / 'part_v_authorization.sql').read_text())
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM app_users WHERE role="GENERAL_ADMIN"').fetchone()[0],1)

    def test_05_prevent_foundation_deletion(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('DELETE FROM app_users WHERE id=?',(FOUNDATION,))

    def test_06_prevent_foundation_deactivation(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE app_users SET is_active=0 WHERE id=?',(FOUNDATION,))

    def test_07_prevent_foundation_role_change(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE app_users SET role="SUPERVISOR" WHERE id=?',(FOUNDATION,))

    def test_08_prevent_foundation_verifier_overwrite(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE app_users SET password_hash="replacement" WHERE id=?',(FOUNDATION,))

    def test_09_prevent_foundation_rename(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE app_users SET username="renamed" WHERE id=?',(FOUNDATION,))

    def test_10_prevent_second_general_admin(self):
        self.person()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO app_users(id,username,normalized_username,
            person_id,role,password_hash,created_at,updated_at)
            VALUES ('another','another','another','p','GENERAL_ADMIN','hash',?,?)''',(NOW,NOW))

    def test_11_prevent_duplicate_foundational_username(self):
        self.person()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO app_users(id,username,normalized_username,
            person_id,role,password_hash,created_at,updated_at)
            VALUES ('another','adwas','adwas','p','SUPERVISOR','hash',?,?)''',(NOW,NOW))

    def test_12_non_foundational_accounts_require_person(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO app_users(id,username,normalized_username,
            person_id,role,password_hash,created_at,updated_at)
            VALUES ('u','u','u',NULL,'SUPERVISOR','hash',?,?)''',(NOW,NOW))

    def test_13_normal_account_can_deactivate(self):
        self.user()
        self.db.execute('UPDATE app_users SET is_active=0,is_deleted=1 WHERE id="u"')
        self.assertEqual(self.db.execute('SELECT is_active,is_deleted FROM app_users WHERE id="u"').fetchone(),(0,1))

    def test_14_normal_account_cannot_physically_delete(self):
        self.user()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('DELETE FROM app_users WHERE id="u"')

    def test_15_normal_account_cannot_escalate_role(self):
        self.user()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE app_users SET role="ORDINARY_ADMIN" WHERE id="u"')

    def test_16_deleted_account_cannot_reactivate(self):
        self.user()
        self.db.execute('UPDATE app_users SET is_active=0,is_deleted=1 WHERE id="u"')
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE app_users SET is_active=1,is_deleted=0 WHERE id="u"')

    def test_17_non_foundational_password_may_change(self):
        self.user()
        self.db.execute('UPDATE app_users SET password_hash="new-hash" WHERE id="u"')
        self.assertEqual(self.db.execute('SELECT password_hash FROM app_users WHERE id="u"').fetchone()[0], 'new-hash')

    def test_19_compiled_assets_do_not_expose_plaintext_secret(self):
        for root in (BASE / "lib",BASE / "assets"):
            for path in root.rglob("*"):
                if path.is_file():
                    self.assertNotIn(bytes([97, 100, 119, 97, 115, 50, 48, 49, 57, 49, 49, 51]).decode(),path.read_text(encoding="utf-8"))

    def test_20_no_online_auth_backend_in_compiled_sources(self):
        source="\n".join(x.read_text(encoding="utf-8") for x in (BASE / "lib").rglob("*.dart"))
        for disallowed in ("package:firebase_", "package:supabase_", "package:dio/", "package:http/"):
            self.assertNotIn(disallowed,source)

    def test_18_no_conflict_with_previous_sql_constraints(self):
        self.user()
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])


if __name__ == '__main__':
    unittest.main()

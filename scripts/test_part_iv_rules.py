"""Real in-memory SQLite integration tests for PART IV (no production data)."""
from __future__ import annotations

import sqlite3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / 'assets' / 'database'
BASE = (SCRIPTS / 'schema_v1.sql').read_text(encoding='utf-8')
SEED = (SCRIPTS / 'seed_v1.sql').read_text(encoding='utf-8')
RULES = (SCRIPTS / 'part_iv_rules.sql').read_text(encoding='utf-8')
STATS = (SCRIPTS / 'part_iv_statistics.sql').read_text(encoding='utf-8')
NOW = '2026-10-13T17:00:00Z'
PRESENT = '00000000-0000-4000-8000-000000000011'
ABSENT = '00000000-0000-4000-8000-000000000013'
UNDEFINED = '00000000-0000-4000-8000-000000000001'


class PartIVRulesTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.execute('PRAGMA foreign_keys = ON')
        for source in (BASE, SEED, RULES):
            self.db.executescript(source)
        self.site('a', 'موقع أ')
        self.site('b', 'موقع ب')

    def tearDown(self):
        self.db.close()

    def site(self, sid, name):
        self.db.execute('''INSERT INTO sites
         (id,name,normalized_name,is_system_site,is_active,created_at,updated_at)
         VALUES (?,?,?,0,1,?,?)''', (sid,name,name,NOW,NOW))

    def person(self, pid='p', number='001', site='a', from_date='2026-10-01'):
        self.db.execute('''INSERT INTO persons
         (id,personnel_number,normalized_personnel_number,full_name,
         normalized_name,lifecycle_status,created_at,updated_at)
         VALUES (?,?,?,'سالم','سالم','ACTIVE',?,?)''', (pid, number, number,NOW,NOW))
        self.assign(pid,site,from_date)

    def assign(self, pid, sid, start, end=None):
        self.db.execute('''INSERT INTO person_site_assignments
         (id,person_id,site_id,effective_from,effective_to_exclusive,assignment_reason,created_at)
         VALUES (?,?,?,?,?,'TEST',?)''',
                        (f'{pid}-{sid}-{start}',pid,sid,start,end,NOW))

    def end_assignment(self, pid, sid, end):
        self.db.execute('''UPDATE person_site_assignments SET effective_to_exclusive=?
            WHERE person_id=? AND site_id=? AND effective_to_exclusive IS NULL''', (end,pid,sid))

    def attendance(self, pid, day, site='a', status=PRESENT):
        self.db.execute('''INSERT INTO daily_attendance
         (id,person_id,attendance_date,effective_site_id,status_id,
          prepared_at,updated_at,revision) VALUES (?,?,?,?,?,?,?,1)''',
                        (f'd-{pid}-{day}',pid,day,site,status,NOW,NOW))

    def transfer(self, pid='p', day='2026-10-10', src='a', dst='b'):
        self.end_assignment(pid,src,day)
        self.assign(pid,dst,day)
        self.db.execute('''INSERT INTO internal_transfers
          (id,person_id,from_site_id,to_site_id,effective_date,executed_at)
          VALUES (?,?,?,?,?,?)''', (f't-{pid}-{day}',pid,src,dst,day,NOW))

    def depart(self, kind, day='2026-10-10', pid='p', site='a'):
        if kind == 'dismissed':
            self.db.execute('''INSERT INTO dismissals
              (id,person_id,previous_site_id,reason,effective_date,executed_at)
              VALUES (?,?,?,'مخالفة',?,?)''', (f'x-{pid}',pid,site,day,NOW))
            status = 'DISMISSED'
        else:
            self.db.execute('''INSERT INTO external_transfers
              (id,person_id,previous_site_id,external_destination,effective_date,executed_at)
              VALUES (?,?,?,'جهة خارجية',?,?)''',(f'x-{pid}',pid,site,day,NOW))
            status = 'EXTERNALLY_TRANSFERRED'
        self.end_assignment(pid,site,day)
        self.db.execute('UPDATE persons SET lifecycle_status=? WHERE id=?',(status,pid))

    def totals(self, day, site=None):
        rows = dict(self.db.execute(STATS,{'report_date':day,'site_id':site}).fetchall())
        return rows

    def seal(self, month=9, year=2026):
        self.db.execute('''INSERT INTO monthly_archives
          (id,year,month,archive_version,closed_at,closed_by_system,integrity_hash,is_sealed)
          VALUES (?,?,?,1,?,1,'test-integrity',1)''',
          (f'm-{year}-{month}',year,month,NOW))

    def test_01_zero_force(self):
        self.assertEqual(self.totals('2026-10-10'), {})

    def test_02_force_unprepared_not_absent(self):
        self.person()
        self.assertEqual(self.totals('2026-10-04'), {'__UNPREPARED__': 1})

    def test_03_one_attendance_one_unprepared(self):
        self.person(); self.person('q','002')
        self.attendance('p','2026-10-04')
        self.assertEqual(self.totals('2026-10-04'), {PRESENT:1,'__UNPREPARED__':1})
        self.assertEqual(sum(self.totals('2026-10-04').values()),2)

    def test_04_status_counts_custom_and_site_filter(self):
        self.person(); self.person('q','002',site='b')
        self.attendance('p','2026-10-05',status=ABSENT)
        self.assertEqual(self.totals('2026-10-05','a'),{ABSENT:1})
        self.assertEqual(self.totals('2026-10-05','b'),{'__UNPREPARED__':1})

    def test_05_pre_admission_not_counted(self):
        self.person(from_date='2026-10-10')
        self.assertEqual(self.totals('2026-10-09'),{})
        self.assertEqual(self.totals('2026-10-10'),{'__UNPREPARED__':1})

    def test_06_transfer_on_day_counts_destination_only(self):
        self.person()
        self.attendance('p','2026-10-09')
        self.transfer()
        self.attendance('p','2026-10-10',site='b')
        self.assertEqual(self.totals('2026-10-09','a'),{PRESENT:1})
        self.assertEqual(self.totals('2026-10-10','a'),{})
        self.assertEqual(self.totals('2026-10-10','b'),{PRESENT:1})

    def test_07_movement_markers_and_attendance_are_distinct_rows(self):
        self.person()
        self.transfer()
        self.attendance('p','2026-10-10',site='b')
        rows=self.db.execute('''SELECT site_id,kind,status_id FROM v_monthly_cell_events
          WHERE person_id='p' AND day='2026-10-10' ORDER BY kind''').fetchall()
        self.assertEqual(len(rows),3)
        self.assertIn(('a','INTERNAL_TRANSFER_OUT',None),rows)
        self.assertIn(('b','INTERNAL_TRANSFER_IN',None),rows)
        self.assertIn(('b','ATTENDANCE',PRESENT),rows)

    def test_08_cannot_attend_on_former_site_transfer_day(self):
        self.person(); self.transfer()
        with self.assertRaises(sqlite3.IntegrityError):
            self.attendance('p','2026-10-10','a')

    def test_09_cannot_attend_before_assignment(self):
        self.person(from_date='2026-10-10')
        with self.assertRaises(sqlite3.IntegrityError):
            self.attendance('p','2026-10-09')

    def test_10_cannot_attend_after_assignment_end(self):
        self.person(); self.end_assignment('p','a','2026-10-10')
        with self.assertRaises(sqlite3.IntegrityError):
            self.attendance('p','2026-10-10')

    def test_11_repeated_same_day_transfers_rejected(self):
        self.person(); self.transfer()
        self.end_assignment('p','b','2026-10-11'); self.assign('p','a','2026-10-11')
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO internal_transfers
             (id,person_id,from_site_id,to_site_id,effective_date,executed_at)
             VALUES ('another','p','b','a','2026-10-10',?)''',(NOW,))

    def test_12_two_transfers_on_different_dates(self):
        self.person(); self.transfer()
        self.end_assignment('p','b','2026-10-20')
        self.assign('p','a','2026-10-20')
        self.db.execute('''INSERT INTO internal_transfers VALUES
          ('t2','p','b','a','2026-10-20',?,NULL,NULL)''',(NOW,))
        self.assertEqual(self.totals('2026-10-10','b'),{'__UNPREPARED__':1})
        self.assertEqual(self.totals('2026-10-20','a'),{'__UNPREPARED__':1})

    def test_13_invalid_transfer_source_rejected(self):
        self.person()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO internal_transfers
              (id,person_id,from_site_id,to_site_id,effective_date,executed_at)
              VALUES ('t','p','b','a','2026-10-10',?)''',(NOW,))

    def test_14_lifecycle_cannot_change_without_departure(self):
        self.person()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE persons SET lifecycle_status='DISMISSED' WHERE id='p'")

    def test_15_dismissal_preserves_history_not_active(self):
        self.person(); self.attendance('p','2026-10-09')
        self.depart('dismissed')
        self.assertEqual(self.totals('2026-10-09'),{PRESENT:1})
        self.assertEqual(self.totals('2026-10-10'),{})
        self.assertEqual(self.db.execute("SELECT lifecycle_status FROM persons WHERE id='p'").fetchone()[0], 'DISMISSED')
        self.assertIn(('a','DISMISSED',None),self.db.execute('''SELECT site_id,kind,status_id
          FROM v_monthly_cell_events WHERE person_id='p' AND day='2026-10-10' ''').fetchall())

    def test_16_external_transfer_preserves_history(self):
        self.person(); self.attendance('p','2026-10-08')
        self.depart('external')
        self.assertEqual(self.totals('2026-10-08'),{PRESENT:1})
        self.assertEqual(self.totals('2026-10-10'),{})
        self.assertEqual(self.db.execute('SELECT count(*) FROM daily_attendance').fetchone()[0],1)

    def test_17_no_attendance_after_dismissal(self):
        self.person(); self.depart('dismissed')
        with self.assertRaises(sqlite3.IntegrityError):
            self.attendance('p','2026-10-15')

    def test_18_backdated_departure_conflicting_future_attendance_blocked(self):
        self.person(); self.attendance('p','2026-10-15')
        with self.assertRaises(sqlite3.IntegrityError):
            self.depart('dismissed',day='2026-10-10')

    def test_19_cannot_dismiss_then_externally_transfer(self):
        self.person(); self.depart('dismissed')
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO external_transfers
              (id,person_id,previous_site_id,external_destination,effective_date,executed_at)
              VALUES ('et','p','a','other','2026-10-11',?)''',(NOW,))

    def test_20_sealed_month_blocks_attendance_insert_and_update(self):
        self.person(from_date='2026-09-01')
        self.attendance('p','2026-09-03')
        self.seal()
        with self.assertRaises(sqlite3.IntegrityError):
            self.attendance('p','2026-09-04')
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE daily_attendance SET revision=2 WHERE person_id='p'")

    def test_21_protect_historical_month_assignments(self):
        self.person(from_date='2026-09-01')
        self.seal()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE person_site_assignments SET site_id='b' WHERE person_id='p'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("DELETE FROM person_site_assignments WHERE person_id='p'")

    def test_22_current_month_transfer_after_sealed_month_works(self):
        self.person(from_date='2026-09-01')
        self.seal()
        self.transfer()
        self.assertEqual(self.totals('2026-09-28','a'),{'__UNPREPARED__':1})
        self.assertEqual(self.totals('2026-10-10','b'),{'__UNPREPARED__':1})

    def test_23_sealed_archive_cannot_appear_twice(self):
        self.seal()
        with self.assertRaises(sqlite3.IntegrityError):
            self.seal()

    def test_24_repeated_status_on_one_day_is_rejected(self):
        self.person(); self.attendance('p','2026-10-08')
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO daily_attendance
              (id,person_id,attendance_date,effective_site_id,status_id,
              prepared_at,updated_at) VALUES('new','p','2026-10-08','a',?,?,?)''',
              (ABSENT,NOW,NOW))

    def test_25_all_events_retained_and_no_person_deletion(self):
        self.person(); self.transfer()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("DELETE FROM persons WHERE id='p'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('DELETE FROM internal_transfers')

    def test_26_sealed_month_prevents_backdated_departure(self):
        self.person(from_date='2026-09-01'); self.seal()
        with self.assertRaises(sqlite3.IntegrityError):
            self.depart('external',day='2026-09-15')

    def test_27_fixed_date_invariant_independent_of_current_lifecycle(self):
        self.person(); self.attendance('p','2026-10-01')
        self.depart('dismissed')
        self.assertEqual(self.totals('2026-10-01'),{PRESENT:1})
        self.assertEqual(self.totals('2026-10-11'),{})

    def test_28_monthly_event_projection_can_search_by_site(self):
        self.person(); self.transfer()
        sites = self.db.execute('''SELECT DISTINCT site_id FROM v_monthly_cell_events
            WHERE person_id='p' AND day='2026-10-10' ''').fetchall()
        self.assertEqual({r[0] for r in sites},{'a','b'})

    def test_29_invalid_transfer_rolls_back_entire_transaction(self):
        self.person()
        self.db.commit()
        with self.assertRaises(sqlite3.IntegrityError):
            with self.db:
                self.end_assignment('p','a','2026-10-10')
                self.assign('p','b','2026-10-10')
                self.db.execute('''INSERT INTO internal_transfers
                 (id,person_id,from_site_id,to_site_id,effective_date,executed_at)
                 VALUES ('bad','p','b','a','2026-10-10',?)''',(NOW,))
        self.assertEqual(self.totals('2026-10-11','a'),{'__UNPREPARED__':1})
        self.assertEqual(self.totals('2026-10-11','b'),{})
        self.assertEqual(self.db.execute('SELECT count(*) FROM internal_transfers').fetchone()[0],0)

    def test_30_cannot_move_a_historical_attendance_to_wrong_site(self):
        self.person()
        self.attendance('p','2026-10-07')
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE daily_attendance SET effective_site_id='b' WHERE person_id='p'")

    def test_31_backdated_external_departure_cannot_invalidate_transfer(self):
        self.person()
        self.transfer()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO external_transfers
              (id,person_id,previous_site_id,external_destination,effective_date,executed_at)
              VALUES ('et','p','a','external','2026-10-10',?)''',(NOW,))

    def test_33_transfer_rejects_unreconciled_day_attendance(self):
        self.person()
        self.attendance('p','2026-10-10',site='a')
        self.end_assignment('p','a','2026-10-10')
        self.assign('p','b','2026-10-10')
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('''INSERT INTO internal_transfers
              (id,person_id,from_site_id,to_site_id,effective_date,executed_at)
              VALUES ('t','p','a','b','2026-10-10',?)''',(NOW,))
        self.db.execute("UPDATE daily_attendance SET effective_site_id='b' WHERE person_id='p'")
        self.db.execute('''INSERT INTO internal_transfers
          (id,person_id,from_site_id,to_site_id,effective_date,executed_at)
          VALUES ('t','p','a','b','2026-10-10',?)''',(NOW,))
        self.assertEqual(self.totals('2026-10-10','b'),{PRESENT:1})

    def test_32_force_reconciles_even_with_new_configured_status(self):
        self.person()
        self.person('q','002')
        self.person('r','003',site='b')
        self.db.execute('''INSERT INTO attendance_statuses
          (id,name,short_code,color_argb,display_order,is_system_status,is_active,created_at,updated_at)
          VALUES ('new','تكليف','ت',4278255360,4,0,1,?,?)''',(NOW,NOW))
        self.attendance('p','2026-10-03',status='new')
        self.attendance('r','2026-10-03',site='b',status=ABSENT)
        status_counts=self.totals('2026-10-03')
        self.assertEqual(status_counts, {'new':1,ABSENT:1,'__UNPREPARED__':1})
        self.assertEqual(sum(status_counts.values()),3)


if __name__ == '__main__':
    unittest.main()

# التمام اليومي — Altamam Al-Yawmi (Flutter Windows)

**PART IV — Database Integrity & Business Rules**  
**Version 0.0.4+4 — Business-engine test milestone; NOT a released personnel system.**

This source ZIP is a direct continuation of the PART III release verified by the user with GitHub Actions. Keep the same private repository `Win-manger`, package ID `adwas_personnel`, Arabic window/program title **التمام اليومي**, and all original documentation and source files.

## Implemented in this milestone

- Everything from PART III remains, including the 29-table source schema, personnel number protections, default `غير محدد` site, immutable historical records, and all existing tests.
- `lib/core/dates/business_date.dart`: Gregorian civil date parsing, validation, weekday/Arabic abbreviation, 28/29/30/31-day calendar, local date vs UTC event timestamps.
- `lib/core/domain/force/force_engine.dart`: pure, deterministic personnel timeline validation, half-open site assignments, historical eligibility/counts, `unprepared` separated from absence, and site-specific monthly cells with independent attendance and movement annotations.
- `lib/core/domain/archives/month_boundary_planner.dart`: chronological missing-month detection, avoids sealing the current month, and rejects writes to old months and future dates.
- `lib/core/domain/archives/month_transition_service.dart`: transactional archive-store interface and fail-closed startup/rollover coordination to be connected **only after encrypted persistence** exists.
- `assets/database/part_iv_rules.sql`: SQLite enforcement for effective-site attendance, departures, same-day transfer conflict, immutable completed months, historical assignments and append-only movements.
- `assets/database/part_iv_statistics.sql`: parameterized historical-force query by date and optional site, with no dependence on the person's present-day lifecycle flag.
- `v_monthly_cell_events`: independent transfer-in, transfer-out, dismissal, external-transfer and attendance rows, including both attendance+transfer-in on the same destination day.
- **58 local Python/SQLite tests passed** (includes previous tests; 33 new PART IV tests). Added Dart unit tests that will be executed on Windows by GitHub Actions.
- Previous GitHub Actions Flutter SDK and Dart Pub caches remain enabled for compatible jobs. Only new/modified code should be recompiled; do not cache stale compiled EXEs.

## Explicit implementation boundary

No plaintext disk database or production personnel records have been enabled. The encrypted native SQLite backend, production repositories, login/session services, operational screens, and the **encrypted archive adapter responsible for transactional snapshots and seals** are not yet implemented. This milestone establishes and tests the relevant rules, *not* an already operational automatic archival job. Without a secure database adapter the Windows foundation screen is intentionally read-only.

The business specifications of PART III remain authoritative; PART IV supplies additional invariants, not schema replacement. Before enabling production persistence, the versioned migration system must apply the PART IV overlay, and the encrypted archive adapter must atomically write person snapshots, day statuses, movements, integrity hash and sealed archive status. A failure must prevent writing a new month.

## Build and acceptance gate

1. Extract this source ZIP and replace files at the root of private GitHub repository `Win-manger` branch `main`. **Include `.github/`**. Do not upload the ZIP as a single repository file.
2. Open Actions → **Windows foundation build** and inspect the new run.
3. Require successful **Validate Part III + Part IV SQLite business integrity** (Python unit tests), Flutter analysis, Flutter unit/widget tests, and Windows release build.
4. Verify the **Show dependency cache status** step; a cache miss on changed SDK/dependency hashes is normal.
5. Download the artifact named **Altamam_AlYawmi_Part_IV_Windows_x64**. Extract its nested ZIP, keeping the executable, DLLs and `data` directory together.
6. Run **التمام اليومي.exe** on a Windows 10/11 x64 PC and ensure it shows the PART IV milestone header. Its interface deliberately has no personnel-entry workflows at this stage.
7. **Do not start the next part until the run succeeds.** Send the Actions summary or the detailed error log for repair.

### Optional local checks on a Windows Flutter machine

```powershell
python -m unittest discover -s scripts -p 'test_*.py' -v
python scripts/validate_contract.py
.\scripts\prepare_windows.ps1
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build windows --release --no-pub
.\scripts\package_windows.ps1
```

Never commit real personnel data, unencrypted databases, backups, credentials or encryption keys. The source archive is not a license to use this milestone as a finished personnel application.

For requirements coverage and decisions, see `docs/PART_IV_IMPLEMENTATION_REPORT.md`.

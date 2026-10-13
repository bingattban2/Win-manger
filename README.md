# التمام اليومي — Windows (Flutter)

**PART III — Permanent Personnel Identification & Exact Business Data Model**  
**Version 0.0.3+3 — structural smoke-test, not yet a production personnel system**

This is a continuation of the previously successfully built **Part II** private GitHub project, not a replacement. The public-facing Windows title and packaged executable remain **التمام اليومي**, while the stable Dart package name is `adwas_personnel`.

## What is now implemented

- The Arabic business terminology of Part II, unchanged, including **الرقم (ع)**.
- Immutable UUID v4 person identifiers and searchable yet display-preserving Arabic/Persian numeral normalization.
- Canonical, relational SQLite schema in `assets/database/schema_v1.sql`: **29 tables** (27 specified + 2 historical integrity tables), foreign keys, uniqueness indexes and protecting triggers.
- Permanent reservation of used business numbers, including corrected/retired numbers, preventing another individual from reusing them.
- Protected default site `غير محدد` and all four default daily attendance statuses with fixed ARGB colors.
- In-memory database tests enforcing assignment interval non-overlap, daily attendance uniqueness, archive sealing, soft-delete integrity, audit append-only behavior and more.
- GitHub Actions Windows smoke-build with **cached Flutter SDK and Dart Pub packages**. Windows executable / artifact naming remains Arabic.
- No unencrypted operational database files and no seeded passwords.

## Architectural boundary

**This release implements PART III only.** The SQL schema is actually executed and tested against a real SQLite engine in-memory. The Windows UI intentionally does *not* persist real personnel data yet: activation of a disk database is blocked pending verified encrypted SQLite and key handling (later specified persistence phases). It would be unsafe to save real individual details unencrypted merely to make this stage look functional.

PART IV business logic (historical force counting, transfers, monthly rollover, etc.) has **not** been built; it is intentionally separate, as requested. Authentication, real screens, backups, Excel and installer work also remain for their corresponding engineering phases.

## Update your private GitHub repository `Win-manger`

1. Extract the **source** ZIP; upload/replace its **contents** at the root of the existing `main` branch, including hidden `.github/workflows/windows-foundation.yml`. Do not upload the source ZIP itself as a repository file.
2. Open **Actions → Windows foundation build** and wait for a new run.
3. Confirm the `Validate Part III SQLite tables and integrity constraints`, `Static analysis`, `Unit and widget tests`, and `Build Windows release` steps are all green.
4. Inspect `Show dependency cache status`: a cache miss can occur when the SDK/version/hash changes; future compatible runs should reuse the cache.
5. Download the **Altamam_AlYawmi_Part_III_Windows_x64** artifact. Inside it, extract `Altamam_AlYawmi_Part_III_Windows_x64.zip`, preserving the entire folder structure.
6. On Windows 10/11 x64, open **التمام اليومي.exe** and confirm the title and read-only **الجزء الثالث — نموذج البيانات** screen. No personnel import should be attempted yet.
7. Send the job result or failing-step logs. **Stop before moving to PART IV.**

The portable test bundle doesn't create a desktop shortcut; the later Installer will create one under the name «التمام اليومي».

## Local repeatable checks (Windows development machine)

```powershell
flutter doctor -v
flutter config --enable-windows-desktop
.\scripts\prepare_windows.ps1
python -m unittest discover -s scripts -p "test_*.py" -v
flutter pub get
dart format lib test
flutter analyze
flutter test
python scripts/validate_contract.py
flutter build windows --release --no-pub
.\scripts\package_windows.ps1
```

**Security:** Use a private GitHub repository. Never upload real personnel lists, databases, backups, encryption keys, passwords, `.env` files or other secrets. A `.gitignore` protects common sensitive paths; review `git status` before committing.

For the exact table design and scope report, read `docs/DATA_MODEL.md` and `docs/PART_III_IMPLEMENTATION_REPORT.md`. The complete 43-phase redacted contract and traceability documentation remain in `docs/`.

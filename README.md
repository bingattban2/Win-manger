# التمام اليومي — ADWAS Personnel

**PART VI — Application Architecture and Operation Pipeline**  
**Version 0.0.6+6** — source foundation, **NOT** a production personnel system.

This milestone extends the verified Part V project in the existing private
GitHub repository `Win-manger`. The Windows desktop executable remains
**التمام اليومي.exe** and Arabic business terminology is unchanged.

## Added in PART VI

- Defined all required feature-layer boundaries, keeping unimplemented
  modules as directories rather than fabricated working screens.
- Built `OperationCoordinator` for normalized input, validation, session and
  permission checks, stale-preview detection, explicit confirmation,
  transactional updates, history, audit, invariant verification, and refresh.
- Added an implementable Site Rename business operation, plus a separate
  domain model and repository interface.
- Added a composition root, role-filtered navigation descriptors, typed
  error results with safe Arabic messages, and a fail-closed persistence port.
- Added Dart business-operation tests and SQLite rollback proofs.
- Preserved the entire Part III–V codebase, SQL test suite, native Windows
  packaging scripts, full requirements traceability, and dependency caches.

**No production personnel/accounts database has been enabled.** The encrypted
SQLite driver and durable transaction implementation remain later phases.
The previous test-only account management service is not a production action
and still needs to adopt this operation pipeline when wired to storage.

## Build and testing

See `docs/BUILD_GUIDE_AR.md`. Windows release CI is mandatory; an independent
**optional, manually triggered Android read-only UI preview** lets a user
without a Windows computer view the Flutter foundation interface on a phone.
The APK preview is not the Windows EXE and does not verify Windows behavior.

Do not proceed to the next milestone until the Windows build is green.

## PART VI build hotfix — GitHub ignore path conflict

The first PART VI CI run failed at `test_01_feature_boundaries_exist` because the
original unanchored `backups/` ignore rule silently excluded the *source*
folder `lib/features/backups/`, including its `.gitkeep` markers.

This source archive changes only the root-level ignore exclusions and adds a
regression test (`test_00_gitignore_keeps_feature_layers_trackable`) executed
with Git's own ignore engine. It leaves runtime logic, database schema,
release version (`0.0.6+6`) and cached Flutter/Dart dependencies untouched.

Upload the entire replacement source archive, **including hidden `.gitkeep`
files in every feature layer**. GitHub Actions must turn green before proceeding
to PART VII. Full details: `docs/PART_VI_BUILD_HOTFIX.md`.

## PART VI build hotfix 02 — fast failing CI and visible backup layer files

The attached user log references old commit `eb3eacf98ea26b1ad4785e78f0aa3acef4ee7c7c`
(91 tests), while the corrected commit `036c980ba082717238fbce970e3ddaa2819435f4`
was already present in GitHub. This archive adds non-hidden `README.md` layer
markers for the backup module so mobile upload tools cannot accidentally
leave empty Git directories. It also runs the Python/SQLite tests BEFORE
restoring ~1.8 GB of Flutter SDK cache, reducing time wasted if source checks
fail. Caching remains ON for valid builds. The version stays `0.0.6+6`.

See `docs/PART_VI_BUILD_HOTFIX_02.md`.

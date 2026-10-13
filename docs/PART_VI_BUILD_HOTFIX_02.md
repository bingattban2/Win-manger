# PART VI — GitHub build fix 02

## Evidence from the user-supplied document

The submitted DOC log is for old commit `eb3eacf98ea26b1ad4785e78f0aa3acef4ee7c7c`,
where `test_01_feature_boundaries_exist` failed for `backups/presentation` in a
91-test run. The GitHub repository was independently verified to have a newer
commit `036c980ba082717238fbce970e3ddaa2819435f4`, already containing the
previous `.gitignore` correction and all five `.gitkeep` files. Therefore that
log is not evidence of a *new* failure in the updated commit.

## This package changes only GitHub CI/source markers

1. Replace hidden `.gitkeep` files in all five backup layer directories with
   visible, useful `README.md` source architecture markers. No executable
   backup functionality is falsely claimed.
2. Run Python/SQLite contract tests before restoring the large Flutter cache.
3. Log Git commit SHA and tracked backups files in the CI job immediately
   after checkout. Fail early if any visible markers are missing.
4. Add a regression test for the markers and CI step ordering.
5. Preserve Windows artifact naming, version, business rules, role matrix,
   `.gitignore` protections, and Flutter/Dart Pub caching.

## How to verify

- Upload the complete ZIP contents to existing `Win-manger` repository.
- In GitHub inspect `lib/features/backups/presentation/README.md` and the
  four other backup layers (all five must exist).
- Check latest GitHub Actions run SHA. It must not be `eb3eacf...`.
- Python test count should now be **93**, not 91 or 92.
- Wait until `flutter analyze`, `flutter test`, Windows build and artifact
  upload all succeed. Passing Python tests alone is insufficient.

The source archive was locally tested; the native Windows build was not run
inside the author's environment.

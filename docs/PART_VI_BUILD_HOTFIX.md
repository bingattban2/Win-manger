# PART VI — GitHub build correction (2026-10-13)

## Observed failure

- Workflow: `Windows foundation build`
- Step: `Validate Part III–VI database, security, and architecture`
- Result: 91 tests ran; 90 passed, 1 failed.
- Failure: `test_part_vi_architecture.PartVIArchitectureTests.test_01_feature_boundaries_exist`
- Assertion: `('backups', 'presentation')` is not a directory in the checkout.

## Verified root cause

Git ignore pattern `backups/` without a leading slash matches nested directories
with that name, including `lib/features/backups/`. The previous source ZIP
contained all the `.gitkeep` files, but Git rejected them when adding files
to the repository. No issue was shown in the Python/SQLite business tests.

## Correction

- Root-anchor sensitive *directories* `/backups/`, `/data/`, `/user_data/`,
  `/secrets/`, `/private/`; keep global ignores for `*.db`, SQLite journals,
  keys and backups. This keeps actual stored data private without dropping
  similarly named source modules.
- Add a Git-engine-based regression test covering all 17 feature modules ×
  five layers, and affirming that root/private user storage remains excluded.
- Keep Flutter and Pub caches unchanged; the log demonstrated both were hits.
- Keep code, schema, tests, UX, application version and artifact name stable.

## Required GitHub verification

1. Upload **all** files from the corrected source ZIP into the existing private
   repository, including `.github/` and the hidden `.gitkeep` markers.
2. In the GitHub changed-files view, confirm files under
   `lib/features/backups/` appear as newly added (at least the five layer
   `.gitkeep` files).
3. Observe `Windows foundation build` and verify the Python tests now pass.
4. Do not consider the fix complete until `flutter analyze`, `flutter test`,
   `flutter build windows --release`, and artifact upload also succeed.
5. Send the log if a *new* failure appears later; the previous log stopped
   before running Flutter compilation.

This is a build-source correction, not a completed personnel-management app.

# Part II Implementation Report — Fixed Arabic Terminology / Windows Product Title

## Scope

Approved business labels from the owner's Part II specification and the new Windows display name «التمام اليومي». Existing foundation and phase-00 traceability remain untouched.

## Code changes

1. `lib/core/config/business_terms.dart`: typed fixed vocabulary with exactly 20 contract labels.
2. `lib/core/config/project_info.dart`: Windows/Flutter display title and current foundation build version.
3. `lib/features/foundation/presentation/foundation_screen.dart`: read-only visual display of approved terminology, not pretend navigation or functional screens.
4. `test/business_terms_test.dart`: exact contract assertions; `test/foundation_screen_test.dart`: UI checks.
5. `scripts/patch_windows_metadata.py`: validates and modifies the Flutter-generated `main.cpp` and resource display labels using wide C++ escapes and UTF-8 resource encoding, without renaming internal project files.
6. `scripts/prepare_windows.ps1`: native Flutter runner preparation applies and verifies branding each time.
7. `scripts/package_windows.ps1`: packages full portable Release contents and renames only the delivered executable to `التمام اليومي.exe`.
8. `.github/workflows/windows-foundation.yml`: Node 24-compatible checkout/artifact Actions, explicit SDK/Pub caching, Python metadata unit tests, naming check, and updated artifact label.
9. `docs/TERMINOLOGY.md`: source-of-truth UI contract.

## Cache design

The successful first build already had `subosito/flutter-action@v2 cache:true`. This update explicitly enables both `cache:true` and `pub-cache:true`, prints cache hit status, and preserves reuse of SDK and Pub dependency downloads between successful runs. The job still re-compiles changed source for correctness. No unsafe native build-output cache is introduced.

## Tests and known acceptance status

- **Earlier Phase 00 GitHub evidence:** screenshot of commit `33a3963`, `Windows foundation build #1`, result `Success`, duration 5m14s, artifact count 1. This verifies CI for the *previous* commit, not the new Part II changes.
- **Part II local check:** Python metadata unit tests and docs checks to be run in preparation; see delivery report.
- **Part II Flutter compile, tests, and Windows native linking:** require a new GitHub Actions run on the updated commit. Not executed in the current authoring environment.
- **Running the executable on a physical Windows desktop:** must be performed by the owner after obtaining the artifact. A successful compilation is not equivalent to a desktop runtime test.

## Gate

**DO NOT START THE NEXT PART UNTIL:** GitHub Actions succeeds on the new source and the Windows artifact contains `التمام اليومي.exe` with the correct window title. Report any failed step's complete log for patching the same codebase.

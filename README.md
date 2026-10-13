# التمام اليومي — Altamam Al-Yawmi (Flutter Windows)

**PART V — Account and Authorization Policy**  
Version **0.0.5+5** · Source milestone (not a production personnel application).

This source archive extends the GitHub-successful PART IV build. Keep the same
private GitHub repository `Win-manger`, package name `adwas_personnel`,
Windows title and executable **التمام اليومي**. No existing business modules
or SQLite constraints were removed.

## Added in this stage

- Typed roles and permissions for all ordinary operations, with **full ordinary
  access for supervisors** but **zero account-management permission**.
- General administrator may create/manage ordinary administrators and
  supervisors; ordinary administrators may manage supervisors only.
- Local account authentication services with a 10-minute inactivity timeout,
  session tokens, disabling/soft-deleting accounts, and login-failure throttling.
- Precomputed salted password hash for the fixed foundational administrator;
  no plaintext password in application source or shipped SQL assets.
- Password-format enforcement for newly created non-foundational accounts.
- SQL overlays protecting the founding account, blocking role changes, hard
  deletion and account resurrection; previous database schema remains intact.
- Additional Python/SQLite and Dart tests for the specified account matrix.

**Security boundary:** The application still intentionally does NOT create a
plaintext SQLite file or store real accounts on disk. Until the dedicated
native encrypted SQLite phase connects the account store, the desktop UI
remains an honest, read-only construction screen. The Part V service layer is
real and tested, but it is not yet an operational production login page.

## GitHub CI: release test gate

1. Extract ZIP, upload **its contents** to repository root (including `.github`).
2. Wait for Actions → `Windows foundation build`.
3. Check Python/SQLite tests, `flutter analyze`, `flutter test`, and Windows
   Release build. Flutter SDK and Dart Pub caches remain enabled.
4. Download `Altamam_AlYawmi_Part_V_Windows_x64` from the Actions artifact.
5. Extract the built package, and run **التمام اليومي.exe** on Windows 10/11.
6. Send the outcome. **Pause next work until this build is verified.**

See `docs/PART_V_IMPLEMENTATION_REPORT.md` for source/tests/limitations and
`docs/TRACEABILITY_MATRIX.csv` for the unchanged complete specification.

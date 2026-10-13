# التمام اليومي — Windows (Flutter)

**Part II: Fixed Arabic terminology / Windows product title · Foundation version 0.0.2 · not production-ready**

This repository is a Flutter Windows project for a fully offline personnel administration and monthly force-accountability system. It is still a foundation smoke-test application: operational screens, encrypted SQLite, accounts, transfers, exports, and archival functions are implemented in their **later** phases, not impersonated by dummy buttons.

## Included now

- Single-source fixed Arabic business terminology — `lib/core/config/business_terms.dart` and `docs/TERMINOLOGY.md`.
- Product name **التمام اليومي** in Flutter app title, Windows window caption, Windows resources, and the packaged `.exe` filename.
- Flutter foundation screen that truthfully displays the contract-approved Arabic terms as read-only labels.
- Existing complete 43-phase traceability documentation and Phase-00 tests retained.
- GitHub Actions native Windows build and portable smoke-test ZIP.
- Explicit Flutter SDK **and Dart Pub** caches (reused between successful runs); `actions/checkout@v6`, `actions/upload-artifact@v6` for Node.js 24 compatibility.
- Deterministic tests for business-term names and native Windows branding.

## Upload to your existing private GitHub repository (Win-manger)

1. Extract this ZIP on your device.
2. **Update the existing private repository:** upload/replace files in the repository root on branch `main`. Keep the hidden `.github/` directory, especially `.github/workflows/windows-foundation.yml`.
3. Do **not** upload the ZIP as one single GitHub repository file: upload its extracted contents.
4. Open **Actions → Windows foundation build** and watch the new run.
5. Verify each step is green, then download the artifact **Altamam_AlYawmi_Part_II_Windows_x64**.
6. Extract the artifact ZIP and then the enclosed `Altamam_AlYawmi_Part_II_Windows_x64.zip` file.
7. On a Windows 10/11 x64 computer, run **التمام اليومي.exe** from the extracted directory, alongside the DLLs and `data/` folder. Confirm the title bar and on-screen title say «التمام اليومي» and the label `الرقم (ع)` appears correctly.
8. Report CI outcome and any runtime fault before proceeding to the next development part.

**Important:** The app does not create a desktop shortcut in this stage. The future Installer will create one named «التمام اليومي». At present, the executable itself is named «التمام اليومي.exe».

## Verify the code locally (Windows dev environment)

```powershell
flutter doctor -v
flutter config --enable-windows-desktop
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\prepare_windows.ps1
python -m unittest discover -s scripts -p "test_*.py" -v
flutter pub get
dart format lib test
flutter analyze
flutter test
python scripts/validate_contract.py
flutter build windows --release --no-pub
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package_windows.ps1
```

The **internal** Dart package name and generated Flutter target remain `adwas_personnel` for stability; only the user-facing product title and distributed EXE are Arabic. Future feature work must use the terms and IDs in `docs/TERMINOLOGY.md`.

## Security & project status

- GitHub must remain **Private**; do not upload personnel spreadsheets, `.db` files, backups, encryption keys, or customer data.
- The foundational administrator's password must never appear in code, build logs, or the UI as plaintext. Its eventual provisioning/authentication is assigned to phase 09; it is **not** enabled in this package.
- This app is not yet fit for operational personnel records. Database encryption belongs to phase 04.
- Refer to `docs/PART_II_IMPLEMENTATION_REPORT.md`, `docs/PHASE_REPORT_00.md`, and the preserved requirements traceability for delivery status.

# Morse (HarmonyOS) — Project Summary

## Overview
- HarmonyOS application named "morse" (`bundleName`: `com.douhua.morsecode`).
- Stage model app with one entry module and a backup extension.
- Target/compatible SDK: 5.1.0(18); device types: phone, tablet.

## Features
- UIAbility `EntryAbility` loads `pages/Index`.
- `Index.ets` shows a simple text that toggles from "Hello World" to "Welcome" on tap.
- Backup extension `EntryBackupAbility` (type: `backup`) implements `onBackup` and `onRestore` stubs; backup is allowed via `profile/backup_config.json`.

## Key Modules & Files
- App manifest: `AppScope/app.json5` (bundle metadata, app icon/label).
- Entry module manifest: `entry/src/main/module.json5` (abilities, pages, extension abilities).
- UI Ability: `entry/src/main/ets/entryability/EntryAbility.ets` (window lifecycle, content loading).
- Backup Extension: `entry/src/main/ets/entrybackupability/EntryBackupAbility.ets`.
- Main page: `entry/src/main/ets/pages/Index.ets`.
- Resources: `entry/src/main/resources` (colors, strings, media, profiles).
- Build configs: `build-profile.json5`, `entry/build-profile.json5`, `hvigorfile.ts`, `entry/hvigorfile.ts`, `hvigor/hvigor-config.json5`.
- Packages: `oh-package.json5`, `entry/oh-package.json5` (uses Hypium for tests).

## Project Structure (high level)
```
AppScope/
entry/
  src/
    main/
      ets/ (EntryAbility, Index page, Backup extension)
      resources/ (media, elements, profiles)
    ohosTest/ (ability-level tests)
    test/ (local unit tests)
build-profile.json5
hvigorfile.ts
hvigor/hvigor-config.json5
```

## Build & Run
- Recommended: use DevEco Studio (HarmonyOS) to open the project and run on an emulator or device.
- CLI (if configured): run with Hvigor tasks from project root. Common flows in HarmonyOS use DevEco’s build/run; CLI availability depends on local setup.
  - Ensure SDK/NDK and Hvigor are installed and environment variables are configured.
  - Note: signing config is present for a local debug profile; avoid committing private keys and passwords.

## Testing
- Unit tests (Hypium): `entry/src/test/*.test.ets`.
- Ability tests: `entry/src/ohosTest/ets/test/*.test.ets`.
- Run via DevEco Studio’s test runner; CLI support depends on local Hvigor/test tooling versions.

## Configuration Notes
- Signing: `build-profile.json5` references a local debug certificate/profile and passwords in the user config directory. Treat these as sensitive; rotate or remove before sharing the repo.
- Obfuscation: `entry/build-profile.json5` has obfuscation rules disabled by default with `obfuscation-rules.txt` placeholder.

## Next Steps (suggested)
- Replace placeholder UI with actual Morse code features (encode/decode, playback, input).
- Add state management, routing, and persistence as needed.
- Expand tests to cover UI interactions and backup/restore flows.


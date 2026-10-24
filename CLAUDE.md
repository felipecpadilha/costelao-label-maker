# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Costelao Label Maker is a Flutter app for a restaurant kitchen: it prints food expiry labels and free-text labels on Bluetooth thermal printers (TSPL), and manages products, responsible staff (responsaveis), technical recipe sheets (fichas tecnicas), suppliers and stock checklists. All data lives in a local SQLite database. UI text and domain names are in Portuguese (pt-BR).

## Commands

```bash
flutter pub get
flutter run                      # Android device recommended (real Bluetooth printing)
flutter run -d windows           # desktop runs too; printing is a stub off-mobile
flutter analyze                  # some known lint/deprecation warnings exist; they don't block builds
flutter test                     # all tests in test/
flutter test test/checklist_report_test.dart                 # single file
flutter test test/checklist_report_test.dart --plain-name "gera relatorio"   # single test by name
dart run flutter_launcher_icons  # regenerate app icons from lib/assets/LogoApp.png
```

Tests live in `test/`. The `tests/{unit,integration,e2e}` and `docs/adr` folders exist but are empty.

## Architecture

Code is organized by feature under `lib/src/features/<feature>/`, with shared infra in `lib/src/core/` (database, router, theme). There are two coexisting styles; match the one already used by the feature you touch:

- **Clean architecture + BLoC** (`products`, `responsaveis`, `fichas_tecnicas`): `data/{datasources,models,repositories}` → `domain/{entities,models,repositories,usecases}` → `presentation/{bloc,pages}`. One usecase class per CRUD operation. Dependencies are wired by hand in `lib/src/app.dart`: repositories and usecases are registered in a `MultiRepositoryProvider`, and BLoCs in a `MultiBlocProvider` that reads usecases via `context.read`. A new feature in this style has to be registered there.
- **Lightweight service + StatefulWidget** (`fornecedores`, `produtos_estoque`, `checklist_estoque`, `settings`, `impressao`): a plain `*Service` class in `data/` that queries `AppDatabase` directly, consumed by pages with no BLoC and no DI registration.

`features/labels` is legacy: an in-memory datasource that isn't routed or provided in `app.dart`.

### Startup (`lib/main.dart`)
- `databaseFactory` is overridden globally: `sqflite_common_ffi` on every non-web platform (including Android/iOS) and `sqflite_common_ffi_web` on web.
- Android Bluetooth/location permissions are requested before `runApp`.

### Database (`lib/src/core/database/app_database.dart`)
- Singleton `AppDatabase.instance.database`, a file `label_maker.db` in the app documents directory.
- Schema changes need all three of: (1) bump `version`, (2) add the table/column to `onCreate`, (3) add a `if (oldVersion < N)` branch in `onUpgrade`. `onOpen` also runs defensive `_ensure*`/`_addColumnIfMissing` helpers to repair databases that drifted; extend those when a column or table must be guaranteed.
- `produtos_estoque.fornecedor_id` uses `ON DELETE RESTRICT`, so suppliers in use can't be deleted.

### Backup (`lib/src/features/settings/data/database_backup_service.dart`)
Exports and restores JSON using the `_backupTables` list, which holds every table ordered parents before children. Restore inserts in that order and deletes in reverse. A new table won't be backed up until it's added to that list; bump `_backupSchemaVersion` along with it. Restore only replaces the tables present in the file, so older backups leave newer tables untouched.

### Navigation (`lib/src/core/router/app_router.dart`)
A single `GoRouter` with flat routes. Detail and edit screens receive their object via `state.extra` (e.g. `Product`, `FichaTecnica`, `ChecklistRelatorio`) and fall back to the list page if `extra` has the wrong type, so pass objects with `context.push(path, extra: obj)`, not as path params.

### Printing (`lib/src/features/impressao/data/services/`)
`TsplBluetoothPrinterService` is an abstract API (`getPairedPrinters`, `printLabel`, `printCustomTextLabel`) whose implementation is chosen by conditional import: `_mobile.dart` when `dart.library.io` exists (uses `print_bluetooth_thermal`, connects by MAC address and sends ASCII TSPL), otherwise `_stub.dart`. Get an instance through `createTsplBluetoothPrinterService()`. Text is sanitized to ASCII because some printers reject unsupported characters.

### Fichas tecnicas
Preparation steps are stored as `flutter_quill` Delta JSON (`modo_preparo_json`), the product image as base64 in the row, and video as either a Google Drive URL or a local file path (played with `video_player`). `FlutterQuillLocalizations.delegate` must stay in `MaterialApp.localizationsDelegates`.

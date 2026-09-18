import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';

const int _backupSchemaVersion = 4;
const String _fixedBackupFileName = 'label_maker_backup_latest.json';
const String _backupPrefix = 'label_maker_backup_';

class DatabaseBackupService {
  DatabaseBackupService({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<bool> requestSaveToDownloadsPermission() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return true;
    return _requestAndroidStoragePermission();
  }

  Future<String> exportBackupToDownloads({
    bool useFixedFileName = false,
    bool overwriteFixedFile = true,
  }) async {
    if (kIsWeb) {
      throw const BackupException(
        'Backup para downloads nao e suportado no Web.',
      );
    }

    final db = await _database.database;
    final backup = <String, dynamic>{
      'schema_version': _backupSchemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'products': await db.query('products', orderBy: 'id ASC'),
      'responsaveis': await db.query('responsaveis', orderBy: 'id ASC'),
      'fichas_tecnicas': await db.query('fichas_tecnicas', orderBy: 'id ASC'),
      'ficha_tecnica_ingredientes': await db.query(
        'ficha_tecnica_ingredientes',
        orderBy: 'id ASC',
      ),
    };

    final downloadsDir = await _resolveDownloadsDirectory(
      requestPermission: false,
    );
    if (downloadsDir == null) {
      throw const BackupException(
        'Nao foi possivel localizar a pasta Downloads.',
      );
    }

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final now = DateTime.now();
    final generatedFileName =
        'label_maker_backup_${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.json';
    final fileName = useFixedFileName
        ? _fixedBackupFileName
        : generatedFileName;

    final filePath = p.join(downloadsDir.path, fileName);
    final file = File(filePath);

    if (useFixedFileName && !overwriteFixedFile && await file.exists()) {
      throw const BackupException(
        'O arquivo fixo ja existe em Downloads. Ative a sobrescrita para continuar.',
      );
    }

    await file.writeAsString(jsonEncode(backup));

    return file.path;
  }

  Future<BackupFileInfo?> getLatestBackupInfo() async {
    if (kIsWeb) return null;

    final downloadsDir = await _resolveDownloadsDirectory(
      requestPermission: false,
    );
    if (downloadsDir == null || !await downloadsDir.exists()) {
      return null;
    }

    final files = downloadsDir.listSync().whereType<File>().where((file) {
      final name = p.basename(file.path);
      return name == _fixedBackupFileName ||
          (name.startsWith(_backupPrefix) && name.endsWith('.json'));
    }).toList();

    if (files.isEmpty) return null;

    files.sort((a, b) {
      final aModified = a.statSync().modified;
      final bModified = b.statSync().modified;
      return bModified.compareTo(aModified);
    });

    final latest = files.first;
    final stat = latest.statSync();
    return BackupFileInfo(
      filePath: latest.path,
      fileName: p.basename(latest.path),
      modifiedAt: stat.modified,
      sizeBytes: stat.size,
    );
  }

  Future<void> restoreBackupFromJsonFile() async {
    if (kIsWeb) {
      throw const BackupException(
        'Recuperacao de backup nao e suportada no Web.',
      );
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      throw const BackupCanceledException();
    }

    final filePath = result.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      throw const BackupException('Arquivo de backup invalido.');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw const BackupException('Arquivo selecionado nao existe.');
    }

    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const BackupException('JSON de backup invalido.');
    }

    _validateSchemaVersion(decoded);

    final products = _asMapList(decoded['products']);
    final responsaveis = _asMapList(decoded['responsaveis']);
    final fichasTecnicas = _asMapList(decoded['fichas_tecnicas']);
    final fichaIngredientes = _asMapList(decoded['ficha_tecnica_ingredientes']);

    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('ficha_tecnica_ingredientes');
      await txn.delete('fichas_tecnicas');
      await txn.delete('products');
      await txn.delete('responsaveis');

      await _insertAll(txn, 'products', products);
      await _insertAll(txn, 'responsaveis', responsaveis);
      await _insertAll(txn, 'fichas_tecnicas', fichasTecnicas);
      await _insertAll(txn, 'ficha_tecnica_ingredientes', fichaIngredientes);
    });
  }

  Future<void> _insertAll(
    Transaction txn,
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      await txn.insert(
        table,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map((item) => item.map((k, v) => MapEntry('$k', v)))
        .toList();
  }

  void _validateSchemaVersion(Map<String, dynamic> decoded) {
    final rawSchema = decoded['schema_version'];
    if (rawSchema == null) {
      throw const BackupException(
        'Arquivo de backup sem schema_version. Backup invalido.',
      );
    }

    if (rawSchema is! int) {
      throw const BackupException(
        'schema_version invalido no arquivo de backup.',
      );
    }

    if (rawSchema > _backupSchemaVersion) {
      throw BackupException(
        'Backup de versao mais nova (schema_version=$rawSchema). Atualize o aplicativo antes de restaurar.',
      );
    }

    if (rawSchema < 1) {
      throw const BackupException(
        'schema_version invalido no arquivo de backup.',
      );
    }
  }

  Future<Directory?> _resolveDownloadsDirectory({
    bool requestPermission = true,
  }) async {
    if (Platform.isAndroid) {
      if (requestPermission) {
        final hasPermission = await _requestAndroidStoragePermission();
        if (!hasPermission) {
          throw const BackupException(
            'Permissao de armazenamento negada para salvar em Downloads.',
          );
        }
      }

      return Directory('/storage/emulated/0/Download');
    }

    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;

    return getApplicationDocumentsDirectory();
  }

  Future<bool> _requestAndroidStoragePermission() async {
    final manage = await Permission.manageExternalStorage.request();
    if (manage.isGranted) return true;

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupCanceledException implements Exception {
  const BackupCanceledException();
}

class BackupFileInfo {
  const BackupFileInfo({
    required this.filePath,
    required this.fileName,
    required this.modifiedAt,
    required this.sizeBytes,
  });

  final String filePath;
  final String fileName;
  final DateTime modifiedAt;
  final int sizeBytes;
}

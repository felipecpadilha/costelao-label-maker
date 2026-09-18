import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/ficha_tecnica_model.dart';

class FichaTecnicaLocalDatasource {
  FichaTecnicaLocalDatasource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<FichaTecnicaModel>> getAll() async {
    final db = await _database.database;
    await _ensureVideoColumns(db);
    final fichasRows = await db.query(
      'fichas_tecnicas',
      orderBy: 'nome_produto ASC',
    );

    final ingredientesRows = await db.query(
      'ficha_tecnica_ingredientes',
      orderBy: 'id ASC',
    );

    final ingredientesPorFicha = <int, List<FichaTecnicaIngredienteModel>>{};
    for (final row in ingredientesRows) {
      final fichaId = row['ficha_tecnica_id'] as int;
      final ingrediente = FichaTecnicaIngredienteModel.fromMap(row);
      ingredientesPorFicha.putIfAbsent(fichaId, () => []).add(ingrediente);
    }

    final fichas = <FichaTecnicaModel>[];
    for (final row in fichasRows) {
      final fichaId = row['id'] as int;
      final ingredientes =
          ingredientesPorFicha[fichaId] ??
          const <FichaTecnicaIngredienteModel>[];

      fichas.add(FichaTecnicaModel.fromMap(row, ingredientes: ingredientes));
    }

    return fichas;
  }

  Future<void> create(FichaTecnicaModel ficha) async {
    final db = await _database.database;
    await _ensureVideoColumns(db);

    await db.transaction((txn) async {
      final fichaId = await txn.insert('fichas_tecnicas', {
        'nome_produto': ficha.nomeProduto,
        'imagem_produto_base64': ficha.imagemProdutoBase64,
        'modo_preparo_json': ficha.modoPreparoJson,
        'video_drive_url': ficha.videoDriveUrl,
        'video_local_path': ficha.videoLocalPath,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (final ingrediente in ficha.ingredientes) {
        final ingredienteModel = FichaTecnicaIngredienteModel(
          nome: ingrediente.nome,
          quantidade: ingrediente.quantidade,
        );
        await txn.insert(
          'ficha_tecnica_ingredientes',
          ingredienteModel.toMap(fichaTecnicaId: fichaId),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> update(FichaTecnicaModel ficha) async {
    final db = await _database.database;
    await _ensureVideoColumns(db);

    await db.transaction((txn) async {
      await txn.update(
        'fichas_tecnicas',
        {
          'nome_produto': ficha.nomeProduto,
          'imagem_produto_base64': ficha.imagemProdutoBase64,
          'modo_preparo_json': ficha.modoPreparoJson,
          'video_drive_url': ficha.videoDriveUrl,
          'video_local_path': ficha.videoLocalPath,
        },
        where: 'id = ?',
        whereArgs: [ficha.id],
      );

      await txn.delete(
        'ficha_tecnica_ingredientes',
        where: 'ficha_tecnica_id = ?',
        whereArgs: [ficha.id],
      );

      for (final ingrediente in ficha.ingredientes) {
        final ingredienteModel = FichaTecnicaIngredienteModel(
          nome: ingrediente.nome,
          quantidade: ingrediente.quantidade,
        );
        await txn.insert(
          'ficha_tecnica_ingredientes',
          ingredienteModel.toMap(fichaTecnicaId: ficha.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> delete(int id) async {
    final db = await _database.database;

    await db.transaction((txn) async {
      await txn.delete(
        'ficha_tecnica_ingredientes',
        where: 'ficha_tecnica_id = ?',
        whereArgs: [id],
      );

      await txn.delete('fichas_tecnicas', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> _ensureVideoColumns(Database db) async {
    await _addColumnIfMissing(db, 'fichas_tecnicas', 'video_drive_url');
    await _addColumnIfMissing(db, 'fichas_tecnicas', 'video_local_path');
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String tableName,
    String columnName,
  ) async {
    final tableExists = await _tableExists(db, tableName);
    if (!tableExists) {
      return;
    }

    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final alreadyExists = columns.any((row) => row['name'] == columnName);
    if (alreadyExists) {
      return;
    }

    await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName TEXT');
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final rows = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', tableName],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}

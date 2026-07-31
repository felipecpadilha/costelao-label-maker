import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/responsavel_model.dart';

class ResponsavelLocalDatasource {
  ResponsavelLocalDatasource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<ResponsavelModel>> getAll() async {
    final db = await _database.database;
    final rows = await db.query('responsaveis', orderBy: 'nome ASC');
    return rows.map(ResponsavelModel.fromMap).toList();
  }

  Future<void> create(ResponsavelModel responsavel) async {
    final db = await _database.database;
    await db.insert('responsaveis', {
      'nome': responsavel.nome,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(ResponsavelModel responsavel) async {
    final db = await _database.database;
    await db.update(
      'responsaveis',
      {'nome': responsavel.nome},
      where: 'id = ?',
      whereArgs: [responsavel.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete('responsaveis', where: 'id = ?', whereArgs: [id]);
  }
}

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/product_model.dart';

class ProductLocalDatasource {
  ProductLocalDatasource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<ProductModel>> getAll() async {
    final db = await _database.database;
    final rows = await db.query('products', orderBy: 'nome ASC');
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<void> create(ProductModel product) async {
    final db = await _database.database;
    await db.insert('products', {
      'nome': product.nome,
      'tempo_de_validade': product.tempoDeValidade,
      'vencimento_dinamico': product.vencimentoDinamico ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(ProductModel product) async {
    final db = await _database.database;
    await db.update(
      'products',
      {
        'nome': product.nome,
        'tempo_de_validade': product.tempoDeValidade,
        'vencimento_dinamico': product.vencimentoDinamico ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}

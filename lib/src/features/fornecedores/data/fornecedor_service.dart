import '../../../core/database/app_database.dart';
import '../domain/models/fornecedor.dart';

class FornecedorService {
  Future<List<Fornecedor>> listar() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('fornecedores', orderBy: 'nome ASC');
    return rows.map(Fornecedor.fromMap).toList();
  }

  Future<int> criar({required String nome, String? telefone}) async {
    final db = await AppDatabase.instance.database;
    return db.insert('fornecedores', {
      'nome': nome.trim(),
      'telefone': telefone?.trim().isEmpty == true ? null : telefone?.trim(),
    });
  }

  Future<void> atualizar({
    required int id,
    required String nome,
    String? telefone,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'fornecedores',
      {
        'nome': nome.trim(),
        'telefone': telefone?.trim().isEmpty == true ? null : telefone?.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> remover(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('fornecedores', where: 'id = ?', whereArgs: [id]);
  }
}

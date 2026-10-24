import '../../../core/database/app_database.dart';
import '../domain/models/produto_estoque.dart';

class ProdutoEstoqueService {
  Future<List<ProdutoEstoque>> listar() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT p.*, f.nome AS fornecedor_nome, f.telefone AS fornecedor_telefone
      FROM produtos_estoque p
      INNER JOIN fornecedores f ON f.id = p.fornecedor_id
      ORDER BY p.nome ASC
    ''');
    return rows.map(ProdutoEstoque.fromMap).toList();
  }

  Future<int> criar({
    required String nome,
    required int estoqueMinimo,
    required int estoqueRecomendado,
    required int fornecedorId,
  }) async {
    final db = await AppDatabase.instance.database;
    return db.insert('produtos_estoque', {
      'nome': nome.trim(),
      'estoque_minimo': estoqueMinimo,
      'estoque_recomendado': estoqueRecomendado,
      'fornecedor_id': fornecedorId,
    });
  }

  Future<void> atualizar({
    required int id,
    required String nome,
    required int estoqueMinimo,
    required int estoqueRecomendado,
    required int fornecedorId,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'produtos_estoque',
      {
        'nome': nome.trim(),
        'estoque_minimo': estoqueMinimo,
        'estoque_recomendado': estoqueRecomendado,
        'fornecedor_id': fornecedorId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> remover(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('produtos_estoque', where: 'id = ?', whereArgs: [id]);
  }
}

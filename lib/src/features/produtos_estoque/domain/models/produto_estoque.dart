class ProdutoEstoque {
  const ProdutoEstoque({
    required this.id,
    required this.nome,
    required this.estoqueMinimo,
    required this.estoqueRecomendado,
    required this.fornecedorId,
    required this.fornecedorNome,
    this.fornecedorTelefone,
  });

  final int id;
  final String nome;
  final int estoqueMinimo;
  final int estoqueRecomendado;
  final int fornecedorId;
  final String fornecedorNome;
  final String? fornecedorTelefone;

  factory ProdutoEstoque.fromMap(Map<String, Object?> map) {
    return ProdutoEstoque(
      id: (map['id'] as int?) ?? 0,
      nome: (map['nome'] as String?) ?? '',
      estoqueMinimo: (map['estoque_minimo'] as int?) ?? 0,
      estoqueRecomendado: (map['estoque_recomendado'] as int?) ?? 0,
      fornecedorId: (map['fornecedor_id'] as int?) ?? 0,
      fornecedorNome: (map['fornecedor_nome'] as String?) ?? 'Fornecedor',
      fornecedorTelefone: map['fornecedor_telefone'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nome': nome,
      'estoque_minimo': estoqueMinimo,
      'estoque_recomendado': estoqueRecomendado,
      'fornecedor_id': fornecedorId,
    };
  }
}

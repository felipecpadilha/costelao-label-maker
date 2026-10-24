class Fornecedor {
  const Fornecedor({required this.id, required this.nome, this.telefone});

  final int id;
  final String nome;
  final String? telefone;

  factory Fornecedor.fromMap(Map<String, Object?> map) {
    return Fornecedor(
      id: (map['id'] as int?) ?? 0,
      nome: (map['nome'] as String?) ?? '',
      telefone: map['telefone'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {'id': id, 'nome': nome, 'telefone': telefone};
  }
}

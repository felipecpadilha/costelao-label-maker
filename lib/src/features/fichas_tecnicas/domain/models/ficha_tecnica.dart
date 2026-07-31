import 'package:equatable/equatable.dart';

class FichaTecnicaIngrediente extends Equatable {
  const FichaTecnicaIngrediente({required this.nome, required this.quantidade});

  final String nome;
  final String quantidade;

  @override
  List<Object> get props => [nome, quantidade];
}

class FichaTecnica extends Equatable {
  const FichaTecnica({
    required this.id,
    required this.nomeProduto,
    required this.imagemProdutoBase64,
    required this.ingredientes,
    required this.modoPreparoJson,
  });

  final int id;
  final String nomeProduto;
  final String? imagemProdutoBase64;
  final List<FichaTecnicaIngrediente> ingredientes;
  final String modoPreparoJson;

  @override
  List<Object?> get props => [
    id,
    nomeProduto,
    imagemProdutoBase64,
    ingredientes,
    modoPreparoJson,
  ];
}

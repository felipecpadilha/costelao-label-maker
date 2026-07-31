import 'package:equatable/equatable.dart';

class FichaTecnicaIngredienteEntity extends Equatable {
  const FichaTecnicaIngredienteEntity({
    required this.nome,
    required this.quantidade,
  });

  final String nome;
  final String quantidade;

  @override
  List<Object> get props => [nome, quantidade];
}

class FichaTecnicaEntity extends Equatable {
  const FichaTecnicaEntity({
    required this.nomeProduto,
    required this.imagemProdutoBase64,
    required this.ingredientes,
    required this.modoPreparoJson,
  });

  final String nomeProduto;
  final String? imagemProdutoBase64;
  final List<FichaTecnicaIngredienteEntity> ingredientes;
  final String modoPreparoJson;

  @override
  List<Object?> get props => [
    nomeProduto,
    imagemProdutoBase64,
    ingredientes,
    modoPreparoJson,
  ];
}

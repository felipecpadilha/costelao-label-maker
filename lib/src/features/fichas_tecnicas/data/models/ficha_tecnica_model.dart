import '../../domain/entities/ficha_tecnica_entity.dart';
import '../../domain/models/ficha_tecnica.dart';

class FichaTecnicaIngredienteModel extends FichaTecnicaIngrediente {
  const FichaTecnicaIngredienteModel({
    required super.nome,
    required super.quantidade,
  });

  factory FichaTecnicaIngredienteModel.fromEntity(
    FichaTecnicaIngredienteEntity entity,
  ) {
    return FichaTecnicaIngredienteModel(
      nome: entity.nome,
      quantidade: entity.quantidade,
    );
  }

  factory FichaTecnicaIngredienteModel.fromMap(Map<String, dynamic> map) {
    return FichaTecnicaIngredienteModel(
      nome: map['nome'] as String,
      quantidade: map['quantidade'] as String,
    );
  }

  Map<String, dynamic> toMap({required int fichaTecnicaId}) {
    return {
      'ficha_tecnica_id': fichaTecnicaId,
      'nome': nome,
      'quantidade': quantidade,
    };
  }
}

class FichaTecnicaModel extends FichaTecnica {
  const FichaTecnicaModel({
    required super.id,
    required super.nomeProduto,
    required super.imagemProdutoBase64,
    required super.ingredientes,
    required super.modoPreparoJson,
    required super.videoDriveUrl,
    required super.videoLocalPath,
  });

  factory FichaTecnicaModel.fromEntity(
    FichaTecnicaEntity entity, {
    required int id,
  }) {
    return FichaTecnicaModel(
      id: id,
      nomeProduto: entity.nomeProduto,
      imagemProdutoBase64: entity.imagemProdutoBase64,
      ingredientes: entity.ingredientes
          .map(FichaTecnicaIngredienteModel.fromEntity)
          .toList(),
      modoPreparoJson: entity.modoPreparoJson,
      videoDriveUrl: entity.videoDriveUrl,
      videoLocalPath: entity.videoLocalPath,
    );
  }

  factory FichaTecnicaModel.fromMap(
    Map<String, dynamic> map, {
    required List<FichaTecnicaIngredienteModel> ingredientes,
  }) {
    return FichaTecnicaModel(
      id: map['id'] as int,
      nomeProduto: map['nome_produto'] as String,
      imagemProdutoBase64: map['imagem_produto_base64'] as String?,
      ingredientes: ingredientes,
      modoPreparoJson: map['modo_preparo_json'] as String,
      videoDriveUrl: map['video_drive_url'] as String?,
      videoLocalPath: map['video_local_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome_produto': nomeProduto,
      'imagem_produto_base64': imagemProdutoBase64,
      'modo_preparo_json': modoPreparoJson,
      'video_drive_url': videoDriveUrl,
      'video_local_path': videoLocalPath,
    };
  }
}

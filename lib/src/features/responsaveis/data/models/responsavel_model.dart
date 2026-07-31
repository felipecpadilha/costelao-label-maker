import '../../domain/entities/responsavel_entity.dart';
import '../../domain/models/responsavel.dart';

class ResponsavelModel extends Responsavel {
  const ResponsavelModel({required super.id, required super.nome});

  factory ResponsavelModel.fromEntity(
    ResponsavelEntity entity, {
    required int id,
  }) {
    return ResponsavelModel(id: id, nome: entity.nome);
  }

  factory ResponsavelModel.fromMap(Map<String, dynamic> map) {
    return ResponsavelModel(id: map['id'] as int, nome: map['nome'] as String);
  }
}

import '../../domain/entities/product_entity.dart';
import '../../domain/models/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.nome,
    required super.tempoDeValidade,
    required super.vencimentoDinamico,
  });

  factory ProductModel.fromEntity(ProductEntity entity, {required int id}) {
    return ProductModel(
      id: id,
      nome: entity.nome,
      tempoDeValidade: entity.tempoDeValidade,
      vencimentoDinamico: entity.vencimentoDinamico,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int,
      nome: map['nome'] as String,
      tempoDeValidade: map['tempo_de_validade'] as int,
      vencimentoDinamico: (map['vencimento_dinamico'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tempo_de_validade': tempoDeValidade,
      'vencimento_dinamico': vencimentoDinamico ? 1 : 0,
    };
  }
}

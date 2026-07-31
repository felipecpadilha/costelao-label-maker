import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.nome,
    required this.tempoDeValidade,
    required this.vencimentoDinamico,
  });

  final String nome;
  final int tempoDeValidade;
  final bool vencimentoDinamico;

  @override
  List<Object> get props => [nome, tempoDeValidade, vencimentoDinamico];
}

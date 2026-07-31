import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.nome,
    required this.tempoDeValidade,
    required this.vencimentoDinamico,
  });

  final int id;
  final String nome;
  final int tempoDeValidade;
  final bool vencimentoDinamico;

  @override
  List<Object> get props => [id, nome, tempoDeValidade, vencimentoDinamico];
}

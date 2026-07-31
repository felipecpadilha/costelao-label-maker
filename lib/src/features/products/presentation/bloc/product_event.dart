import 'package:equatable/equatable.dart';

sealed class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductsStarted extends ProductEvent {
  const ProductsStarted();
}

class ProductCreated extends ProductEvent {
  const ProductCreated({
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

class ProductUpdated extends ProductEvent {
  const ProductUpdated({
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

class ProductDeleted extends ProductEvent {
  const ProductDeleted(this.id);

  final int id;

  @override
  List<Object> get props => [id];
}

import 'package:equatable/equatable.dart';

class Responsavel extends Equatable {
  const Responsavel({required this.id, required this.nome});

  final int id;
  final String nome;

  @override
  List<Object> get props => [id, nome];
}

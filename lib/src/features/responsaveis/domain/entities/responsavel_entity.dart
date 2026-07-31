import 'package:equatable/equatable.dart';

class ResponsavelEntity extends Equatable {
  const ResponsavelEntity({required this.nome});

  final String nome;

  @override
  List<Object> get props => [nome];
}

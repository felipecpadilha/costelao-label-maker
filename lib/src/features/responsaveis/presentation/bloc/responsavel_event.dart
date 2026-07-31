import 'package:equatable/equatable.dart';

sealed class ResponsavelEvent extends Equatable {
  const ResponsavelEvent();

  @override
  List<Object?> get props => [];
}

class ResponsaveisStarted extends ResponsavelEvent {
  const ResponsaveisStarted();
}

class ResponsavelCreated extends ResponsavelEvent {
  const ResponsavelCreated({required this.nome});

  final String nome;

  @override
  List<Object> get props => [nome];
}

class ResponsavelUpdated extends ResponsavelEvent {
  const ResponsavelUpdated({required this.id, required this.nome});

  final int id;
  final String nome;

  @override
  List<Object> get props => [id, nome];
}

class ResponsavelDeleted extends ResponsavelEvent {
  const ResponsavelDeleted(this.id);

  final int id;

  @override
  List<Object> get props => [id];
}

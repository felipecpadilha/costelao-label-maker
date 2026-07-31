import 'package:equatable/equatable.dart';

import '../../domain/entities/ficha_tecnica_entity.dart';

sealed class FichaTecnicaEvent extends Equatable {
  const FichaTecnicaEvent();

  @override
  List<Object?> get props => [];
}

class FichasTecnicasStarted extends FichaTecnicaEvent {
  const FichasTecnicasStarted();
}

class FichaTecnicaCreated extends FichaTecnicaEvent {
  const FichaTecnicaCreated({required this.ficha});

  final FichaTecnicaEntity ficha;

  @override
  List<Object> get props => [ficha];
}

class FichaTecnicaUpdated extends FichaTecnicaEvent {
  const FichaTecnicaUpdated({required this.id, required this.ficha});

  final int id;
  final FichaTecnicaEntity ficha;

  @override
  List<Object> get props => [id, ficha];
}

class FichaTecnicaDeleted extends FichaTecnicaEvent {
  const FichaTecnicaDeleted(this.id);

  final int id;

  @override
  List<Object> get props => [id];
}

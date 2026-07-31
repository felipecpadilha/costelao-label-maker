import 'package:equatable/equatable.dart';

import '../../domain/models/ficha_tecnica.dart';

enum FichaTecnicaStatus { initial, loading, success, failure }

class FichaTecnicaState extends Equatable {
  const FichaTecnicaState({
    this.status = FichaTecnicaStatus.initial,
    this.fichas = const [],
    this.errorMessage,
  });

  final FichaTecnicaStatus status;
  final List<FichaTecnica> fichas;
  final String? errorMessage;

  FichaTecnicaState copyWith({
    FichaTecnicaStatus? status,
    List<FichaTecnica>? fichas,
    String? errorMessage,
  }) {
    return FichaTecnicaState(
      status: status ?? this.status,
      fichas: fichas ?? this.fichas,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, fichas, errorMessage];
}

import 'package:equatable/equatable.dart';

import '../../domain/models/responsavel.dart';

enum ResponsavelStatus { initial, loading, success, failure }

class ResponsavelState extends Equatable {
  const ResponsavelState({
    this.status = ResponsavelStatus.initial,
    this.responsaveis = const [],
    this.errorMessage,
  });

  final ResponsavelStatus status;
  final List<Responsavel> responsaveis;
  final String? errorMessage;

  ResponsavelState copyWith({
    ResponsavelStatus? status,
    List<Responsavel>? responsaveis,
    String? errorMessage,
  }) {
    return ResponsavelState(
      status: status ?? this.status,
      responsaveis: responsaveis ?? this.responsaveis,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, responsaveis, errorMessage];
}

import 'package:equatable/equatable.dart';

import '../../domain/models/label.dart';

enum LabelStatus { initial, loading, success, failure }

class LabelState extends Equatable {
  const LabelState({
    this.status = LabelStatus.initial,
    this.labels = const [],
    this.errorMessage,
  });

  final LabelStatus status;
  final List<Label> labels;
  final String? errorMessage;

  LabelState copyWith({
    LabelStatus? status,
    List<Label>? labels,
    String? errorMessage,
  }) {
    return LabelState(
      status: status ?? this.status,
      labels: labels ?? this.labels,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, labels, errorMessage];
}

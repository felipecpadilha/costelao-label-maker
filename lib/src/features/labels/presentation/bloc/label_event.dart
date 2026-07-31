import 'package:equatable/equatable.dart';

sealed class LabelEvent extends Equatable {
  const LabelEvent();

  @override
  List<Object?> get props => [];
}

class LabelsStarted extends LabelEvent {
  const LabelsStarted();
}

class LabelAdded extends LabelEvent {
  const LabelAdded({
    required this.name,
    required this.width,
    required this.height,
  });

  final String name;
  final double width;
  final double height;

  @override
  List<Object> get props => [name, width, height];
}

class LabelDeleted extends LabelEvent {
  const LabelDeleted(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

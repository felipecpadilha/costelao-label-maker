import 'package:equatable/equatable.dart';

class Label extends Equatable {
  const Label({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double width;
  final double height;
  final DateTime createdAt;

  @override
  List<Object> get props => [id, name, width, height, createdAt];
}

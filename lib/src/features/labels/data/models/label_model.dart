import '../../domain/models/label.dart';

class LabelModel extends Label {
  const LabelModel({
    required super.id,
    required super.name,
    required super.width,
    required super.height,
    required super.createdAt,
  });

  factory LabelModel.fromLabel(Label label) {
    return LabelModel(
      id: label.id,
      name: label.name,
      width: label.width,
      height: label.height,
      createdAt: label.createdAt,
    );
  }

  factory LabelModel.fromMap(Map<String, dynamic> map) {
    return LabelModel(
      id: map['id'] as String,
      name: map['name'] as String,
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'width': width,
      'height': height,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

import 'package:uuid/uuid.dart';

import '../models/label.dart';
import '../repositories/label_repository.dart';

class CreateLabelUsecase {
  CreateLabelUsecase(this._repository);

  final LabelRepository _repository;
  final Uuid _uuid = const Uuid();

  Future<void> call({
    required String name,
    required double width,
    required double height,
  }) {
    final label = Label(
      id: _uuid.v4(),
      name: name,
      width: width,
      height: height,
      createdAt: DateTime.now(),
    );

    return _repository.save(label);
  }
}

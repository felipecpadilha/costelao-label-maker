import '../repositories/label_repository.dart';

class DeleteLabelUsecase {
  const DeleteLabelUsecase(this._repository);

  final LabelRepository _repository;

  Future<void> call(String id) {
    return _repository.delete(id);
  }
}

import '../models/label.dart';
import '../repositories/label_repository.dart';

class GetLabelsUsecase {
  const GetLabelsUsecase(this._repository);

  final LabelRepository _repository;

  Future<List<Label>> call() {
    return _repository.getAll();
  }
}

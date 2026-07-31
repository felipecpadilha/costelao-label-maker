import '../repositories/responsavel_repository.dart';

class DeleteResponsavelUsecase {
  const DeleteResponsavelUsecase(this._repository);

  final ResponsavelRepository _repository;

  Future<void> call(int id) {
    return _repository.delete(id);
  }
}

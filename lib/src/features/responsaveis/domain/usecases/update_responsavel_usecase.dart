import '../entities/responsavel_entity.dart';
import '../repositories/responsavel_repository.dart';

class UpdateResponsavelUsecase {
  const UpdateResponsavelUsecase(this._repository);

  final ResponsavelRepository _repository;

  Future<void> call(int id, ResponsavelEntity responsavel) {
    return _repository.update(id, responsavel);
  }
}

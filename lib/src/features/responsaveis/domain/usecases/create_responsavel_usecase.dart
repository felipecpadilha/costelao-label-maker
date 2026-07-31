import '../entities/responsavel_entity.dart';
import '../repositories/responsavel_repository.dart';

class CreateResponsavelUsecase {
  const CreateResponsavelUsecase(this._repository);

  final ResponsavelRepository _repository;

  Future<void> call(ResponsavelEntity responsavel) {
    return _repository.create(responsavel);
  }
}

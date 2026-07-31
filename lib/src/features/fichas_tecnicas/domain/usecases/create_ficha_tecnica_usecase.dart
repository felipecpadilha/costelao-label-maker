import '../entities/ficha_tecnica_entity.dart';
import '../repositories/ficha_tecnica_repository.dart';

class CreateFichaTecnicaUsecase {
  const CreateFichaTecnicaUsecase(this._repository);

  final FichaTecnicaRepository _repository;

  Future<void> call(FichaTecnicaEntity ficha) {
    return _repository.create(ficha);
  }
}

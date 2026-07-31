import '../entities/ficha_tecnica_entity.dart';
import '../repositories/ficha_tecnica_repository.dart';

class UpdateFichaTecnicaUsecase {
  const UpdateFichaTecnicaUsecase(this._repository);

  final FichaTecnicaRepository _repository;

  Future<void> call(int id, FichaTecnicaEntity ficha) {
    return _repository.update(id, ficha);
  }
}

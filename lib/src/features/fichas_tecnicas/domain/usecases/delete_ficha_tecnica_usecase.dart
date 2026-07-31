import '../repositories/ficha_tecnica_repository.dart';

class DeleteFichaTecnicaUsecase {
  const DeleteFichaTecnicaUsecase(this._repository);

  final FichaTecnicaRepository _repository;

  Future<void> call(int id) {
    return _repository.delete(id);
  }
}

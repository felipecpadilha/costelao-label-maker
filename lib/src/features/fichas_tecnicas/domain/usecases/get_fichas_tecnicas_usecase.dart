import '../models/ficha_tecnica.dart';
import '../repositories/ficha_tecnica_repository.dart';

class GetFichasTecnicasUsecase {
  const GetFichasTecnicasUsecase(this._repository);

  final FichaTecnicaRepository _repository;

  Future<List<FichaTecnica>> call() {
    return _repository.getAll();
  }
}

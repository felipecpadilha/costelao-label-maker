import '../models/responsavel.dart';
import '../repositories/responsavel_repository.dart';

class GetResponsaveisUsecase {
  const GetResponsaveisUsecase(this._repository);

  final ResponsavelRepository _repository;

  Future<List<Responsavel>> call() {
    return _repository.getAll();
  }
}

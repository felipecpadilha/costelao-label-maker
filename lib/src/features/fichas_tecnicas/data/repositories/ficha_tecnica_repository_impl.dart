import '../../domain/entities/ficha_tecnica_entity.dart';
import '../../domain/models/ficha_tecnica.dart';
import '../../domain/repositories/ficha_tecnica_repository.dart';
import '../datasources/ficha_tecnica_local_datasource.dart';
import '../models/ficha_tecnica_model.dart';

class FichaTecnicaRepositoryImpl implements FichaTecnicaRepository {
  const FichaTecnicaRepositoryImpl(this._localDatasource);

  final FichaTecnicaLocalDatasource _localDatasource;

  @override
  Future<List<FichaTecnica>> getAll() {
    return _localDatasource.getAll();
  }

  @override
  Future<void> create(FichaTecnicaEntity ficha) {
    return _localDatasource.create(FichaTecnicaModel.fromEntity(ficha, id: 0));
  }

  @override
  Future<void> update(int id, FichaTecnicaEntity ficha) {
    return _localDatasource.update(FichaTecnicaModel.fromEntity(ficha, id: id));
  }

  @override
  Future<void> delete(int id) {
    return _localDatasource.delete(id);
  }
}

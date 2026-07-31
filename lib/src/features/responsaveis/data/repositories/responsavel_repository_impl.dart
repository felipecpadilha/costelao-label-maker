import '../../domain/entities/responsavel_entity.dart';
import '../../domain/models/responsavel.dart';
import '../../domain/repositories/responsavel_repository.dart';
import '../datasources/responsavel_local_datasource.dart';
import '../models/responsavel_model.dart';

class ResponsavelRepositoryImpl implements ResponsavelRepository {
  const ResponsavelRepositoryImpl(this._localDatasource);

  final ResponsavelLocalDatasource _localDatasource;

  @override
  Future<List<Responsavel>> getAll() {
    return _localDatasource.getAll();
  }

  @override
  Future<void> create(ResponsavelEntity responsavel) {
    return _localDatasource.create(
      ResponsavelModel.fromEntity(responsavel, id: 0),
    );
  }

  @override
  Future<void> update(int id, ResponsavelEntity responsavel) {
    return _localDatasource.update(
      ResponsavelModel.fromEntity(responsavel, id: id),
    );
  }

  @override
  Future<void> delete(int id) {
    return _localDatasource.delete(id);
  }
}

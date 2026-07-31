import '../../domain/models/label.dart';
import '../../domain/repositories/label_repository.dart';
import '../datasources/label_local_datasource.dart';
import '../models/label_model.dart';

class LabelRepositoryImpl implements LabelRepository {
  const LabelRepositoryImpl(this._localDatasource);

  final LabelLocalDatasource _localDatasource;

  @override
  Future<List<Label>> getAll() {
    return _localDatasource.getAll();
  }

  @override
  Future<void> save(Label label) {
    return _localDatasource.save(LabelModel.fromLabel(label));
  }

  @override
  Future<void> delete(String id) {
    return _localDatasource.delete(id);
  }
}

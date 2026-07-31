import '../models/label.dart';

abstract class LabelRepository {
  Future<List<Label>> getAll();

  Future<void> save(Label label);

  Future<void> delete(String id);
}

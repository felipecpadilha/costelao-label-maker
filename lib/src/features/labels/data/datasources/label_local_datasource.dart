import '../models/label_model.dart';

class LabelLocalDatasource {
  LabelLocalDatasource();

  static final List<LabelModel> _labels = [];

  Future<List<LabelModel>> getAll() async {
    final labels = List<LabelModel>.from(_labels);
    labels.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return labels;
  }

  Future<void> save(LabelModel label) async {
    _labels.removeWhere((item) => item.id == label.id);
    _labels.add(label);
  }

  Future<void> delete(String id) async {
    _labels.removeWhere((item) => item.id == id);
  }
}

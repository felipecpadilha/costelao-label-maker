import '../entities/ficha_tecnica_entity.dart';
import '../models/ficha_tecnica.dart';

abstract class FichaTecnicaRepository {
  Future<List<FichaTecnica>> getAll();

  Future<void> create(FichaTecnicaEntity ficha);

  Future<void> update(int id, FichaTecnicaEntity ficha);

  Future<void> delete(int id);
}

import '../entities/responsavel_entity.dart';
import '../models/responsavel.dart';

abstract class ResponsavelRepository {
  Future<List<Responsavel>> getAll();

  Future<void> create(ResponsavelEntity responsavel);

  Future<void> update(int id, ResponsavelEntity responsavel);

  Future<void> delete(int id);
}

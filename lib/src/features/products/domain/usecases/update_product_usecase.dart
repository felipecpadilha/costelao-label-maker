import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class UpdateProductUsecase {
  const UpdateProductUsecase(this._repository);

  final ProductRepository _repository;

  Future<void> call(int id, ProductEntity product) {
    return _repository.update(id, product);
  }
}

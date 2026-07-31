import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class CreateProductUsecase {
  const CreateProductUsecase(this._repository);

  final ProductRepository _repository;

  Future<void> call(ProductEntity product) {
    return _repository.create(product);
  }
}

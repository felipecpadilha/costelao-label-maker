import '../models/product.dart';
import '../repositories/product_repository.dart';

class GetProductsUsecase {
  const GetProductsUsecase(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> call() {
    return _repository.getAll();
  }
}

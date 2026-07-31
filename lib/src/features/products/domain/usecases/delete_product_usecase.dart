import '../repositories/product_repository.dart';

class DeleteProductUsecase {
  const DeleteProductUsecase(this._repository);

  final ProductRepository _repository;

  Future<void> call(int id) {
    return _repository.delete(id);
  }
}

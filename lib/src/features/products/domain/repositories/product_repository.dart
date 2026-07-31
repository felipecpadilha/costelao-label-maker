import '../entities/product_entity.dart';
import '../models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getAll();

  Future<void> create(ProductEntity product);

  Future<void> update(int id, ProductEntity product);

  Future<void> delete(int id);
}

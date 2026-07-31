import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/models/product.dart';
import '../datasources/product_local_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._localDatasource);

  final ProductLocalDatasource _localDatasource;

  @override
  Future<List<Product>> getAll() {
    return _localDatasource.getAll();
  }

  @override
  Future<void> create(ProductEntity product) {
    return _localDatasource.create(ProductModel.fromEntity(product, id: 0));
  }

  @override
  Future<void> update(int id, ProductEntity product) {
    return _localDatasource.update(ProductModel.fromEntity(product, id: id));
  }

  @override
  Future<void> delete(int id) {
    return _localDatasource.delete(id);
  }
}

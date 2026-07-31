import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc(
    this._getProductsUsecase,
    this._createProductUsecase,
    this._updateProductUsecase,
    this._deleteProductUsecase,
  ) : super(const ProductState()) {
    on<ProductsStarted>(_onStarted);
    on<ProductCreated>(_onCreated);
    on<ProductUpdated>(_onUpdated);
    on<ProductDeleted>(_onDeleted);
  }

  final GetProductsUsecase _getProductsUsecase;
  final CreateProductUsecase _createProductUsecase;
  final UpdateProductUsecase _updateProductUsecase;
  final DeleteProductUsecase _deleteProductUsecase;

  void _logError(String context, Object error, StackTrace stackTrace) {
    developer.log(
      context,
      name: 'ProductBloc',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _onStarted(
    ProductsStarted event,
    Emitter<ProductState> emit,
  ) async {
    await _reload(emit);
  }

  Future<void> _onCreated(
    ProductCreated event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _createProductUsecase(
        ProductEntity(
          nome: event.nome,
          tempoDeValidade: event.tempoDeValidade,
          vencimentoDinamico: event.vencimentoDinamico,
        ),
      );
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao criar produto.', error, stackTrace);
      emit(
        state.copyWith(
          status: ProductStatus.failure,
          errorMessage: 'Nao foi possivel criar o produto.',
        ),
      );
    }
  }

  Future<void> _onUpdated(
    ProductUpdated event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _updateProductUsecase(
        event.id,
        ProductEntity(
          nome: event.nome,
          tempoDeValidade: event.tempoDeValidade,
          vencimentoDinamico: event.vencimentoDinamico,
        ),
      );
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao atualizar produto.', error, stackTrace);
      emit(
        state.copyWith(
          status: ProductStatus.failure,
          errorMessage: 'Nao foi possivel atualizar o produto.',
        ),
      );
    }
  }

  Future<void> _onDeleted(
    ProductDeleted event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _deleteProductUsecase(event.id);
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao remover produto.', error, stackTrace);
      emit(
        state.copyWith(
          status: ProductStatus.failure,
          errorMessage: 'Nao foi possivel remover o produto.',
        ),
      );
    }
  }

  Future<void> _reload(Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading));
    try {
      final products = await _getProductsUsecase();
      emit(state.copyWith(status: ProductStatus.success, products: products));
    } catch (error, stackTrace) {
      _logError('Erro ao carregar produtos.', error, stackTrace);
      emit(
        state.copyWith(
          status: ProductStatus.failure,
          errorMessage: 'Nao foi possivel carregar os produtos.',
        ),
      );
    }
  }
}

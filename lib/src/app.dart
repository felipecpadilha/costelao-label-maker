import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/fichas_tecnicas/data/datasources/ficha_tecnica_local_datasource.dart';
import 'features/fichas_tecnicas/data/repositories/ficha_tecnica_repository_impl.dart';
import 'features/fichas_tecnicas/domain/usecases/create_ficha_tecnica_usecase.dart';
import 'features/fichas_tecnicas/domain/usecases/delete_ficha_tecnica_usecase.dart';
import 'features/fichas_tecnicas/domain/usecases/get_fichas_tecnicas_usecase.dart';
import 'features/fichas_tecnicas/domain/usecases/update_ficha_tecnica_usecase.dart';
import 'features/fichas_tecnicas/presentation/bloc/ficha_tecnica_bloc.dart';
import 'features/products/data/datasources/product_local_datasource.dart';
import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/products/domain/usecases/create_product_usecase.dart';
import 'features/products/domain/usecases/delete_product_usecase.dart';
import 'features/products/domain/usecases/get_products_usecase.dart';
import 'features/products/domain/usecases/update_product_usecase.dart';
import 'features/products/presentation/bloc/product_bloc.dart';
import 'features/responsaveis/data/datasources/responsavel_local_datasource.dart';
import 'features/responsaveis/data/repositories/responsavel_repository_impl.dart';
import 'features/responsaveis/domain/usecases/create_responsavel_usecase.dart';
import 'features/responsaveis/domain/usecases/delete_responsavel_usecase.dart';
import 'features/responsaveis/domain/usecases/get_responsaveis_usecase.dart';
import 'features/responsaveis/domain/usecases/update_responsavel_usecase.dart';
import 'features/responsaveis/presentation/bloc/responsavel_bloc.dart';

class LabelMakerApp extends StatelessWidget {
  const LabelMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final productRepository = ProductRepositoryImpl(ProductLocalDatasource());
    final fichaTecnicaRepository = FichaTecnicaRepositoryImpl(
      FichaTecnicaLocalDatasource(),
    );
    final responsavelRepository = ResponsavelRepositoryImpl(
      ResponsavelLocalDatasource(),
    );

    final getProductsUsecase = GetProductsUsecase(productRepository);
    final createProductUsecase = CreateProductUsecase(productRepository);
    final updateProductUsecase = UpdateProductUsecase(productRepository);
    final deleteProductUsecase = DeleteProductUsecase(productRepository);

    final getFichasTecnicasUsecase = GetFichasTecnicasUsecase(
      fichaTecnicaRepository,
    );
    final createFichaTecnicaUsecase = CreateFichaTecnicaUsecase(
      fichaTecnicaRepository,
    );
    final updateFichaTecnicaUsecase = UpdateFichaTecnicaUsecase(
      fichaTecnicaRepository,
    );
    final deleteFichaTecnicaUsecase = DeleteFichaTecnicaUsecase(
      fichaTecnicaRepository,
    );

    final getResponsaveisUsecase = GetResponsaveisUsecase(
      responsavelRepository,
    );
    final createResponsavelUsecase = CreateResponsavelUsecase(
      responsavelRepository,
    );
    final updateResponsavelUsecase = UpdateResponsavelUsecase(
      responsavelRepository,
    );
    final deleteResponsavelUsecase = DeleteResponsavelUsecase(
      responsavelRepository,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: productRepository),
        RepositoryProvider.value(value: getProductsUsecase),
        RepositoryProvider.value(value: createProductUsecase),
        RepositoryProvider.value(value: updateProductUsecase),
        RepositoryProvider.value(value: deleteProductUsecase),
        RepositoryProvider.value(value: fichaTecnicaRepository),
        RepositoryProvider.value(value: getFichasTecnicasUsecase),
        RepositoryProvider.value(value: createFichaTecnicaUsecase),
        RepositoryProvider.value(value: updateFichaTecnicaUsecase),
        RepositoryProvider.value(value: deleteFichaTecnicaUsecase),
        RepositoryProvider.value(value: responsavelRepository),
        RepositoryProvider.value(value: getResponsaveisUsecase),
        RepositoryProvider.value(value: createResponsavelUsecase),
        RepositoryProvider.value(value: updateResponsavelUsecase),
        RepositoryProvider.value(value: deleteResponsavelUsecase),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ProductBloc(
              context.read<GetProductsUsecase>(),
              context.read<CreateProductUsecase>(),
              context.read<UpdateProductUsecase>(),
              context.read<DeleteProductUsecase>(),
            ),
          ),
          BlocProvider(
            create: (context) => ResponsavelBloc(
              context.read<GetResponsaveisUsecase>(),
              context.read<CreateResponsavelUsecase>(),
              context.read<UpdateResponsavelUsecase>(),
              context.read<DeleteResponsavelUsecase>(),
            ),
          ),
          BlocProvider(
            create: (context) => FichaTecnicaBloc(
              context.read<GetFichasTecnicasUsecase>(),
              context.read<CreateFichaTecnicaUsecase>(),
              context.read<UpdateFichaTecnicaUsecase>(),
              context.read<DeleteFichaTecnicaUsecase>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Costelao Label Maker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          localizationsDelegates: const [
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}

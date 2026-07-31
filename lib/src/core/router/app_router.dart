import 'package:go_router/go_router.dart';

import '../../features/fichas_tecnicas/domain/models/ficha_tecnica.dart';
import '../../features/fichas_tecnicas/presentation/pages/ficha_tecnica_detail_page.dart';
import '../../features/fichas_tecnicas/presentation/pages/ficha_tecnica_form_page.dart';
import '../../features/fichas_tecnicas/presentation/pages/ficha_tecnica_view_page.dart';
import '../../features/fichas_tecnicas/presentation/pages/fichas_tecnicas_page.dart';
import '../../features/fichas_tecnicas/presentation/pages/fichas_tecnicas_view_list_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/impressao/presentation/pages/impressao_completar_page.dart';
import '../../features/impressao/presentation/pages/impressao_products_page.dart';
import '../../features/impressao/presentation/pages/impressao_rotulo_page.dart';
import '../../features/products/domain/models/product.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/responsaveis/presentation/pages/responsaveis_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/produtos',
        builder: (context, state) => const ProductsPage(),
      ),
      GoRoute(
        path: '/responsaveis',
        builder: (context, state) => const ResponsaveisPage(),
      ),
      GoRoute(
        path: '/impressao',
        builder: (context, state) => const ImpressaoProductsPage(),
      ),
      GoRoute(
        path: '/impressao/completar',
        builder: (context, state) {
          final product = state.extra;
          if (product is! Product) {
            return const ImpressaoProductsPage();
          }

          return ImpressaoCompletarPage(product: product);
        },
      ),
      GoRoute(
        path: '/impressao/rotulo',
        builder: (context, state) => const ImpressaoRotuloPage(),
      ),
      GoRoute(
        path: '/fichas-tecnicas',
        builder: (context, state) => const FichasTecnicasPage(),
      ),
      GoRoute(
        path: '/fichas-tecnicas/detalhe',
        builder: (context, state) {
          final ficha = state.extra;
          if (ficha is! FichaTecnica) {
            return const FichasTecnicasPage();
          }

          return FichaTecnicaDetailPage(ficha: ficha);
        },
      ),
      GoRoute(
        path: '/fichas-tecnicas/visualizar',
        builder: (context, state) {
          final ficha = state.extra;
          if (ficha is FichaTecnica) {
            return FichaTecnicaViewPage(ficha: ficha);
          }

          return const FichasTecnicasViewListPage();
        },
      ),
      GoRoute(
        path: '/fichas-tecnicas/form',
        builder: (context, state) {
          final ficha = state.extra;
          return FichaTecnicaFormPage(
            ficha: ficha is FichaTecnica ? ficha : null,
          );
        },
      ),
      GoRoute(
        path: '/configuracoes',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../products/domain/models/product.dart';
import '../../../products/presentation/bloc/product_bloc.dart';
import '../../../products/presentation/bloc/product_event.dart';
import '../../../products/presentation/bloc/product_state.dart';

class ImpressaoProductsPage extends StatefulWidget {
  const ImpressaoProductsPage({super.key});

  @override
  State<ImpressaoProductsPage> createState() => _ImpressaoProductsPageState();
}

class _ImpressaoProductsPageState extends State<ImpressaoProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const ProductsStarted());
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final nextValue = _searchController.text.trim().toLowerCase();
        if (nextValue == _searchTerm) return;
        setState(() {
          _searchTerm = nextValue;
        });
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Etiquetas de validade'),
          actions: [
            IconButton(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Home',
            ),
          ],
        ),
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state.status == ProductStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == ProductStatus.failure) {
              return Center(
                child: Text(state.errorMessage ?? 'Erro desconhecido.'),
              );
            }

            if (state.products.isEmpty) {
              return const Center(child: Text('Nenhum produto cadastrado.'));
            }

            final filteredProducts = state.products.where((product) {
              if (_searchTerm.isEmpty) return true;
              return product.nome.toLowerCase().contains(_searchTerm);
            }).toList();

            if (filteredProducts.isEmpty) {
              return const Center(child: Text('Nenhum produto encontrado.'));
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar produto por nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Card(
                        child: ListTile(
                          title: Text(product.nome),
                          subtitle: Text(
                            product.vencimentoDinamico
                                ? 'Vencimento dinamico'
                                : 'Validade: ${product.tempoDeValidade} dia(s)',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openCompletarImpressao(product),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openCompletarImpressao(Product product) {
    context.push('/impressao/completar', extra: product);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/product.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                        onTap: () => _showProductDialog(product: product),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDeleteProduct(product),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),
    );
  }

  Future<void> _showProductDialog({Product? product}) async {
    final initialNome = (product?.nome ?? '').toUpperCase();
    final initialValidade = product?.tempoDeValidade.toString() ?? '';
    var vencimentoDinamico = product?.vencimentoDinamico ?? false;
    var nome = initialNome;
    var validade = initialValidade;

    final result = await showDialog<_ProductDialogResult>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(product == null ? 'Novo produto' : 'Editar produto'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: initialNome,
                    onChanged: (value) => nome = value,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                        );
                      }),
                    ],
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  CheckboxListTile(
                    value: vencimentoDinamico,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vencimento dinamico'),
                    onChanged: (value) {
                      final isChecked = value ?? false;
                      setDialogState(() {
                        vencimentoDinamico = isChecked;
                      });
                      if (isChecked) {
                        validade = '';
                      }
                    },
                  ),
                  if (!vencimentoDinamico)
                    TextFormField(
                      initialValue: initialValidade,
                      onChanged: (value) => validade = value,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Validade (dias)',
                      ),
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nomeFinal = nome.trim().toUpperCase();
                final tempoDeValidade = vencimentoDinamico
                    ? 0
                    : int.tryParse(validade);

                if (nomeFinal.isEmpty ||
                    tempoDeValidade == null ||
                    tempoDeValidade < 0 ||
                    (!vencimentoDinamico && tempoDeValidade < 1)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Informe nome e validade valida ou marque vencimento dinamico.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _ProductDialogResult(
                    nome: nomeFinal,
                    tempoDeValidade: tempoDeValidade,
                    vencimentoDinamico: vencimentoDinamico,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    if (product == null) {
      context.read<ProductBloc>().add(
        ProductCreated(
          nome: result.nome,
          tempoDeValidade: result.tempoDeValidade,
          vencimentoDinamico: result.vencimentoDinamico,
        ),
      );
    } else {
      context.read<ProductBloc>().add(
        ProductUpdated(
          id: product.id,
          nome: result.nome,
          tempoDeValidade: result.tempoDeValidade,
          vencimentoDinamico: result.vencimentoDinamico,
        ),
      );
    }
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar exclusao'),
          content: Text(
            'Deseja realmente excluir o produto "${product.nome}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      context.read<ProductBloc>().add(ProductDeleted(product.id));
    }
  }
}

class _ProductDialogResult {
  const _ProductDialogResult({
    required this.nome,
    required this.tempoDeValidade,
    required this.vencimentoDinamico,
  });

  final String nome;
  final int tempoDeValidade;
  final bool vencimentoDinamico;
}

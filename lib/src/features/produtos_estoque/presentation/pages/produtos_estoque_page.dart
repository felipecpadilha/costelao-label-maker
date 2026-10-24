import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../fornecedores/data/fornecedor_service.dart';
import '../../../fornecedores/domain/models/fornecedor.dart';
import '../../data/produto_estoque_service.dart';
import '../../domain/models/produto_estoque.dart';

class ProdutosEstoquePage extends StatefulWidget {
  const ProdutosEstoquePage({super.key});

  @override
  State<ProdutosEstoquePage> createState() => _ProdutosEstoquePageState();
}

class _ProdutosEstoquePageState extends State<ProdutosEstoquePage> {
  final _service = ProdutoEstoqueService();
  final _fornecedoresService = FornecedorService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchTerm = '';
  List<ProdutoEstoque> _produtos = [];
  List<Fornecedor> _fornecedores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        setState(() {
          _searchTerm = _searchController.text.trim().toLowerCase();
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

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final fornecedores = await _fornecedoresService.listar();
    final produtos = await _service.listar();
    if (!mounted) return;
    setState(() {
      _fornecedores = fornecedores;
      _produtos = produtos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _produtos.where((produto) {
      if (_searchTerm.isEmpty) return true;
      return produto.nome.toLowerCase().contains(_searchTerm) ||
          produto.fornecedorNome.toLowerCase().contains(_searchTerm);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos de estoque'),
        actions: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
          ? const Center(child: Text('Nenhum produto de estoque cadastrado.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar produto ou fornecedor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final produto = filtered[index];
                      return Card(
                        child: ListTile(
                          title: Text(produto.nome),
                          subtitle: Text(
                            'Fornecedor: ${produto.fornecedorNome}\n'
                            'Estoque mínimo: ${produto.estoqueMinimo} | '
                            'Recomendado: ${produto.estoqueRecomendado}',
                          ),
                          isThreeLine: true,
                          onTap: () => _openDialog(produto: produto),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(produto),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),
    );
  }

  Future<void> _openDialog({ProdutoEstoque? produto}) async {
    if (_fornecedores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um fornecedor antes de criar um produto.'),
        ),
      );
      return;
    }

    final nomeController = TextEditingController(text: produto?.nome ?? '');
    final minController = TextEditingController(
      text: produto == null ? '' : produto.estoqueMinimo.toString(),
    );
    final recomendadoController = TextEditingController(
      text: produto == null ? '' : produto.estoqueRecomendado.toString(),
    );
    var fornecedorSelecionado = produto?.fornecedorId ?? _fornecedores.first.id;

    final result = await showDialog<_ProdutoEstoqueDialogResult>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(produto == null ? 'Novo produto' : 'Editar produto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estoque mínimo',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: recomendadoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estoque recomendado',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: fornecedorSelecionado,
                  decoration: const InputDecoration(labelText: 'Fornecedor'),
                  items: _fornecedores
                      .map(
                        (fornecedor) => DropdownMenuItem<int>(
                          value: fornecedor.id,
                          child: Text(fornecedor.nome),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      fornecedorSelecionado = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nome = nomeController.text.trim();
                final estoqueMinimo = int.tryParse(minController.text.trim());
                final estoqueRecomendado = int.tryParse(
                  recomendadoController.text.trim(),
                );

                if (nome.isEmpty ||
                    estoqueMinimo == null ||
                    estoqueRecomendado == null ||
                    estoqueMinimo < 0 ||
                    estoqueRecomendado < 0 ||
                    estoqueRecomendado < estoqueMinimo) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Informe nome, valores válidos e estoques coerentes.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _ProdutoEstoqueDialogResult(
                    nome: nome,
                    estoqueMinimo: estoqueMinimo,
                    estoqueRecomendado: estoqueRecomendado,
                    fornecedorId: fornecedorSelecionado,
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

    if (produto == null) {
      await _service.criar(
        nome: result.nome,
        estoqueMinimo: result.estoqueMinimo,
        estoqueRecomendado: result.estoqueRecomendado,
        fornecedorId: result.fornecedorId,
      );
    } else {
      await _service.atualizar(
        id: produto.id,
        nome: result.nome,
        estoqueMinimo: result.estoqueMinimo,
        estoqueRecomendado: result.estoqueRecomendado,
        fornecedorId: result.fornecedorId,
      );
    }

    await _loadData();
  }

  Future<void> _confirmDelete(ProdutoEstoque produto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar exclusao'),
          content: Text(
            'Deseja realmente excluir o produto "${produto.nome}"?',
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
      await _service.remover(produto.id);
      await _loadData();
    }
  }
}

class _ProdutoEstoqueDialogResult {
  const _ProdutoEstoqueDialogResult({
    required this.nome,
    required this.estoqueMinimo,
    required this.estoqueRecomendado,
    required this.fornecedorId,
  });

  final String nome;
  final int estoqueMinimo;
  final int estoqueRecomendado;
  final int fornecedorId;
}

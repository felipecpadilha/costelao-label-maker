import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../produtos_estoque/data/produto_estoque_service.dart';
import '../../../produtos_estoque/domain/models/produto_estoque.dart';
import '../../domain/models/checklist_relatorio.dart';

class ChecklistEstoquePage extends StatefulWidget {
  const ChecklistEstoquePage({super.key});

  @override
  State<ChecklistEstoquePage> createState() => _ChecklistEstoquePageState();
}

class _ChecklistEstoquePageState extends State<ChecklistEstoquePage> {
  final _service = ProdutoEstoqueService();
  final Map<int, TextEditingController> _quantidadeControllers = {};
  List<ProdutoEstoque> _produtos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProdutos();
  }

  @override
  void dispose() {
    for (final controller in _quantidadeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProdutos() async {
    setState(() => _loading = true);
    final produtos = await _service.listar();
    if (!mounted) return;
    for (final controller in _quantidadeControllers.values) {
      controller.dispose();
    }
    _quantidadeControllers.clear();
    for (final produto in produtos) {
      _quantidadeControllers[produto.id] = TextEditingController();
    }
    setState(() {
      _produtos = produtos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist de estoque'),
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
          : _produtos.isEmpty
          ? const Center(
              child: Text('Cadastre produtos para montar o checklist.'),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _produtos.length,
                      itemBuilder: (context, index) {
                        final produto = _produtos[index];
                        final controller = _quantidadeControllers[produto.id]!;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        produto.nome,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Fornecedor: ${produto.fornecedorNome}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mínimo: ${produto.estoqueMinimo} | Recomendado: ${produto.estoqueRecomendado}',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Qtd atual',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _enviarChecklist,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Enviar checklist'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _enviarChecklist() async {
    final itens = <ChecklistItem>[];

    for (final produto in _produtos) {
      final controller = _quantidadeControllers[produto.id];
      final valor = controller?.text.trim();
      final quantidadeAtual = valor == null || valor.isEmpty
          ? null
          : int.tryParse(valor);

      if (quantidadeAtual == null && valor != null && valor.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantidade inválida para ${produto.nome}. Informe um número inteiro.',
            ),
          ),
        );
        return;
      }

      itens.add(
        ChecklistItem(
          produtoNome: produto.nome,
          fornecedorNome: produto.fornecedorNome,
          fornecedorTelefone: produto.fornecedorTelefone,
          quantidadeAtual: quantidadeAtual,
          estoqueMinimo: produto.estoqueMinimo,
          estoqueRecomendado: produto.estoqueRecomendado,
        ),
      );
    }

    final relatorio = ChecklistRelatorioGenerator.generate(itens);
    if (!mounted) return;
    context.push('/checklist-estoque/relatorio', extra: relatorio);
  }
}

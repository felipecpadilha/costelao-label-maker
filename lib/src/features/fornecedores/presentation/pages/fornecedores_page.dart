import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/fornecedor_service.dart';
import '../../domain/models/fornecedor.dart';

class FornecedoresPage extends StatefulWidget {
  const FornecedoresPage({super.key});

  @override
  State<FornecedoresPage> createState() => _FornecedoresPageState();
}

class _FornecedoresPageState extends State<FornecedoresPage> {
  final _service = FornecedorService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchTerm = '';
  List<Fornecedor> _fornecedores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFornecedores();
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

  Future<void> _loadFornecedores() async {
    setState(() => _loading = true);
    final fornecedores = await _service.listar();
    if (!mounted) return;
    setState(() {
      _fornecedores = fornecedores;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _fornecedores.where((fornecedor) {
      if (_searchTerm.isEmpty) return true;
      return fornecedor.nome.toLowerCase().contains(_searchTerm) ||
          (fornecedor.telefone ?? '').toLowerCase().contains(_searchTerm);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedores'),
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
          ? const Center(child: Text('Nenhum fornecedor cadastrado.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar fornecedor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final fornecedor = filtered[index];
                      return Card(
                        child: ListTile(
                          title: Text(fornecedor.nome),
                          subtitle:
                              fornecedor.telefone == null ||
                                  fornecedor.telefone!.trim().isEmpty
                              ? const Text('Telefone não informado')
                              : Text(fornecedor.telefone!),
                          onTap: () => _openDialog(fornecedor: fornecedor),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(fornecedor),
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
        label: const Text('Novo fornecedor'),
      ),
    );
  }

  Future<void> _openDialog({Fornecedor? fornecedor}) async {
    final nomeController = TextEditingController(text: fornecedor?.nome ?? '');
    final telefoneController = TextEditingController(
      text: fornecedor?.telefone ?? '',
    );

    final result = await showDialog<_FornecedorDialogResult>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            fornecedor == null ? 'Novo fornecedor' : 'Editar fornecedor',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone (opcional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nome = nomeController.text.trim();
                final telefone = telefoneController.text.trim();
                if (nome.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe o nome do fornecedor.'),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _FornecedorDialogResult(
                    nome: nome,
                    telefone: telefone.isEmpty ? null : telefone,
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

    if (fornecedor == null) {
      await _service.criar(nome: result.nome, telefone: result.telefone);
    } else {
      await _service.atualizar(
        id: fornecedor.id,
        nome: result.nome,
        telefone: result.telefone,
      );
    }

    await _loadFornecedores();
  }

  Future<void> _confirmDelete(Fornecedor fornecedor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar exclusao'),
          content: Text(
            'Deseja realmente excluir o fornecedor "${fornecedor.nome}"?',
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
      await _service.remover(fornecedor.id);
      await _loadFornecedores();
    }
  }
}

class _FornecedorDialogResult {
  const _FornecedorDialogResult({required this.nome, this.telefone});

  final String nome;
  final String? telefone;
}

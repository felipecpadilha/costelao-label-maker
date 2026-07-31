import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/responsavel.dart';
import '../bloc/responsavel_bloc.dart';
import '../bloc/responsavel_event.dart';
import '../bloc/responsavel_state.dart';

class ResponsaveisPage extends StatefulWidget {
  const ResponsaveisPage({super.key});

  @override
  State<ResponsaveisPage> createState() => _ResponsaveisPageState();
}

class _ResponsaveisPageState extends State<ResponsaveisPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    context.read<ResponsavelBloc>().add(const ResponsaveisStarted());
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
        title: const Text('Responsaveis'),
        actions: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
          ),
        ],
      ),
      body: BlocBuilder<ResponsavelBloc, ResponsavelState>(
        builder: (context, state) {
          if (state.status == ResponsavelStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ResponsavelStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'Erro desconhecido.'),
            );
          }

          if (state.responsaveis.isEmpty) {
            return const Center(child: Text('Nenhum responsavel cadastrado.'));
          }

          final filteredResponsaveis = state.responsaveis.where((responsavel) {
            if (_searchTerm.isEmpty) return true;
            return responsavel.nome.toLowerCase().contains(_searchTerm);
          }).toList();

          if (filteredResponsaveis.isEmpty) {
            return const Center(child: Text('Nenhum responsavel encontrado.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar responsavel por nome',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filteredResponsaveis.length,
                  itemBuilder: (context, index) {
                    final responsavel = filteredResponsaveis[index];
                    return Card(
                      child: ListTile(
                        title: Text(responsavel.nome),
                        onTap: () =>
                            _showResponsavelDialog(responsavel: responsavel),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              _confirmDeleteResponsavel(responsavel),
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
        onPressed: () => _showResponsavelDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Novo responsavel'),
      ),
    );
  }

  Future<void> _showResponsavelDialog({Responsavel? responsavel}) async {
    final initialNome = responsavel?.nome ?? '';
    var nome = initialNome;

    final result = await showDialog<_ResponsavelDialogResult>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            responsavel == null ? 'Novo responsavel' : 'Editar responsavel',
          ),
          content: TextFormField(
            initialValue: initialNome,
            onChanged: (value) => nome = value,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nomeFinal = nome.trim();
                if (nomeFinal.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe o nome do responsavel.'),
                    ),
                  );
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(_ResponsavelDialogResult(nome: nomeFinal));
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    if (responsavel == null) {
      context.read<ResponsavelBloc>().add(
        ResponsavelCreated(nome: result.nome),
      );
    } else {
      context.read<ResponsavelBloc>().add(
        ResponsavelUpdated(id: responsavel.id, nome: result.nome),
      );
    }
  }

  Future<void> _confirmDeleteResponsavel(Responsavel responsavel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar exclusao'),
          content: Text(
            'Deseja realmente excluir o responsavel "${responsavel.nome}"?',
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
      context.read<ResponsavelBloc>().add(ResponsavelDeleted(responsavel.id));
    }
  }
}

class _ResponsavelDialogResult {
  const _ResponsavelDialogResult({required this.nome});

  final String nome;
}

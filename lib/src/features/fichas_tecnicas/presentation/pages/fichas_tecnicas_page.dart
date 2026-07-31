import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/ficha_tecnica.dart';
import '../bloc/ficha_tecnica_bloc.dart';
import '../bloc/ficha_tecnica_event.dart';
import '../bloc/ficha_tecnica_state.dart';

class FichasTecnicasPage extends StatefulWidget {
  const FichasTecnicasPage({super.key});

  @override
  State<FichasTecnicasPage> createState() => _FichasTecnicasPageState();
}

class _FichasTecnicasPageState extends State<FichasTecnicasPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    context.read<FichaTecnicaBloc>().add(const FichasTecnicasStarted());
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
        title: const Text('Fichas tecnicas'),
        actions: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
          ),
        ],
      ),
      body: BlocBuilder<FichaTecnicaBloc, FichaTecnicaState>(
        builder: (context, state) {
          if (state.status == FichaTecnicaStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == FichaTecnicaStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'Erro desconhecido.'),
            );
          }

          if (state.fichas.isEmpty) {
            return const Center(
              child: Text('Nenhuma ficha tecnica cadastrada.'),
            );
          }

          final filteredFichas = state.fichas.where((ficha) {
            if (_searchTerm.isEmpty) return true;
            return ficha.nomeProduto.toLowerCase().contains(_searchTerm);
          }).toList();

          if (filteredFichas.isEmpty) {
            return const Center(
              child: Text('Nenhuma ficha tecnica encontrada.'),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar ficha tecnica por nome',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filteredFichas.length,
                  itemBuilder: (context, index) {
                    final ficha = filteredFichas[index];
                    return Card(
                      child: ListTile(
                        title: Text(ficha.nomeProduto),
                        subtitle: Text(
                          '${ficha.ingredientes.length} ingrediente(s)',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              onPressed: () => _confirmDeleteFicha(ficha),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remover ficha',
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => _openFichaDetalhe(ficha),
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
        onPressed: _openNovaFicha,
        icon: const Icon(Icons.add),
        label: const Text('Nova ficha tecnica'),
      ),
    );
  }

  Future<void> _openNovaFicha() async {
    final changed = await context.push('/fichas-tecnicas/form');
    if (!mounted || changed != true) return;
    context.read<FichaTecnicaBloc>().add(const FichasTecnicasStarted());
  }

  Future<void> _openFichaDetalhe(FichaTecnica ficha) async {
    final changed = await context.push('/fichas-tecnicas/form', extra: ficha);
    if (!mounted || changed != true) return;
    context.read<FichaTecnicaBloc>().add(const FichasTecnicasStarted());
  }

  Future<void> _confirmDeleteFicha(FichaTecnica ficha) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar exclusao'),
          content: Text(
            'Deseja realmente remover a ficha tecnica "${ficha.nomeProduto}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirm != true) return;

    context.read<FichaTecnicaBloc>().add(FichaTecnicaDeleted(ficha.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ficha tecnica "${ficha.nomeProduto}" removida.')),
    );
  }
}

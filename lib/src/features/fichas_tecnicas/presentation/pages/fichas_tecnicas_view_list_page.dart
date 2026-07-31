import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/ficha_tecnica.dart';
import '../bloc/ficha_tecnica_bloc.dart';
import '../bloc/ficha_tecnica_event.dart';
import '../bloc/ficha_tecnica_state.dart';

class FichasTecnicasViewListPage extends StatefulWidget {
  const FichasTecnicasViewListPage({super.key});

  @override
  State<FichasTecnicasViewListPage> createState() =>
      _FichasTecnicasViewListPageState();
}

class _FichasTecnicasViewListPageState
    extends State<FichasTecnicasViewListPage> {
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
        title: const Text('Visualizar fichas tecnicas'),
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

          final filteredFichas = state.fichas.where((ficha) {
            if (_searchTerm.isEmpty) return true;
            return ficha.nomeProduto.toLowerCase().contains(_searchTerm);
          }).toList();

          if (state.fichas.isEmpty) {
            return const Center(
              child: Text('Nenhuma ficha tecnica cadastrada.'),
            );
          }

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
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openFichaVisualizacao(ficha),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFichaVisualizacao(FichaTecnica ficha) async {
    await context.push('/fichas-tecnicas/visualizar', extra: ficha);
  }
}

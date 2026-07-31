import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';

import '../../domain/models/ficha_tecnica.dart';
import '../bloc/ficha_tecnica_bloc.dart';
import '../bloc/ficha_tecnica_event.dart';

class FichaTecnicaDetailPage extends StatefulWidget {
  const FichaTecnicaDetailPage({required this.ficha, super.key});

  final FichaTecnica ficha;

  @override
  State<FichaTecnicaDetailPage> createState() => _FichaTecnicaDetailPageState();
}

class _FichaTecnicaDetailPageState extends State<FichaTecnicaDetailPage> {
  late FichaTecnica _ficha;
  late final quill.QuillController _modoPreparoController;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _ficha = widget.ficha;
    _imageBytes = _decodeImage(_ficha.imagemProdutoBase64);
    final document = _buildDocument(_ficha.modoPreparoJson);
    _modoPreparoController = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _modoPreparoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualizar ficha tecnica'),
        actions: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
          ),
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _ficha.nomeProduto,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (_imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_imageBytes!, height: 220, fit: BoxFit.cover),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('Sem imagem'),
            ),
          const SizedBox(height: 24),
          Text('Ingredientes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_ficha.ingredientes.isEmpty)
            const Text('Nenhum ingrediente informado.')
          else
            ..._ficha.ingredientes.map(
              (ingrediente) => Card(
                child: ListTile(
                  dense: true,
                  title: Text(ingrediente.nome),
                  subtitle: Text(ingrediente.quantidade),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Modo de preparo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: quill.QuillEditor.basic(
              controller: _modoPreparoController,
              config: const quill.QuillEditorConfig(
                autoFocus: false,
                expands: false,
                scrollable: false,
                minHeight: 120,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEdit,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Editar'),
      ),
    );
  }

  Uint8List? _decodeImage(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  quill.Document _buildDocument(String json) {
    try {
      final deltaJson = jsonDecode(json) as List<dynamic>;
      return quill.Document.fromJson(deltaJson);
    } catch (_) {
      return quill.Document()..insert(0, json);
    }
  }

  Future<void> _openEdit() async {
    final changed = await context.push('/fichas-tecnicas/form', extra: _ficha);
    if (!mounted) return;
    if (changed == true) {
      context.pop(true);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar exclusao'),
          content: Text(
            'Deseja realmente excluir a ficha tecnica de "${_ficha.nomeProduto}"?',
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

    if (confirm != true || !mounted) return;

    context.read<FichaTecnicaBloc>().add(FichaTecnicaDeleted(_ficha.id));
    context.pop(true);
  }
}

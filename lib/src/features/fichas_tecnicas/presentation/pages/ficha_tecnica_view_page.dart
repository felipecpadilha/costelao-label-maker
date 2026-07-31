import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';

import '../../domain/models/ficha_tecnica.dart';

class FichaTecnicaViewPage extends StatefulWidget {
  const FichaTecnicaViewPage({required this.ficha, super.key});

  final FichaTecnica ficha;

  @override
  State<FichaTecnicaViewPage> createState() => _FichaTecnicaViewPageState();
}

class _FichaTecnicaViewPageState extends State<FichaTecnicaViewPage> {
  late final quill.QuillController _modoPreparoController;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _imageBytes = _decodeImage(widget.ficha.imagemProdutoBase64);
    final document = _buildDocument(widget.ficha.modoPreparoJson);
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.ficha.nomeProduto,
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
          if (widget.ficha.ingredientes.isEmpty)
            const Text('Nenhum ingrediente informado.')
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  columns: const [
                    DataColumn(label: Text('Quantidade')),
                    DataColumn(label: Text('Ingrediente')),
                  ],
                  rows: widget.ficha.ingredientes
                      .map(
                        (ingrediente) => DataRow(
                          cells: [
                            DataCell(Text(ingrediente.quantidade)),
                            DataCell(Text(ingrediente.nome)),
                          ],
                        ),
                      )
                      .toList(),
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
}

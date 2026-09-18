import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

import '../../domain/entities/ficha_tecnica_entity.dart';
import '../../domain/models/ficha_tecnica.dart';
import '../bloc/ficha_tecnica_bloc.dart';
import '../bloc/ficha_tecnica_event.dart';

class FichaTecnicaFormPage extends StatefulWidget {
  const FichaTecnicaFormPage({this.ficha, super.key});

  final FichaTecnica? ficha;

  @override
  State<FichaTecnicaFormPage> createState() => _FichaTecnicaFormPageState();
}

class _FichaTecnicaFormPageState extends State<FichaTecnicaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _picker = ImagePicker();

  late final quill.QuillController _modoPreparoController;

  String? _imagemBase64;
  Uint8List? _imagemBytes;
  String? _videoLocalPath;
  bool _isSaving = false;
  bool _isPreviewingVideo = false;
  bool _editorReady = false;
  final List<_IngredienteInput> _ingredientes = [];

  bool get _isEditing => widget.ficha != null;

  @override
  void initState() {
    super.initState();
    final ficha = widget.ficha;
    _nomeController.text = (ficha?.nomeProduto ?? '').toUpperCase();
    _imagemBase64 = ficha?.imagemProdutoBase64;
    _imagemBytes = _decodeImage(_imagemBase64);
    _videoLocalPath = ficha?.videoLocalPath;

    final document = _buildModoPreparoDocument(ficha?.modoPreparoJson);
    _modoPreparoController = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _editorReady = true;
      });
    });

    if (ficha != null && ficha.ingredientes.isNotEmpty) {
      for (final ingrediente in ficha.ingredientes) {
        _ingredientes.add(
          _IngredienteInput(
            nome: ingrediente.nome,
            quantidade: ingrediente.quantidade,
          ),
        );
      }
    } else {
      _ingredientes.add(_IngredienteInput());
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _modoPreparoController.dispose();
    for (final ingrediente in _ingredientes) {
      ingrediente.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar ficha tecnica' : 'Nova ficha tecnica'),
        actions: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return newValue.copyWith(text: newValue.text.toUpperCase());
                }),
              ],
              decoration: const InputDecoration(
                labelText: 'Nome do produto',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do produto.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Imagem do produto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_imagemBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imagemBytes!,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('Nenhuma imagem selecionada'),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Selecionar da galeria'),
                  ),
                ),
                if (_imagemBase64 != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() {
                      _imagemBase64 = null;
                      _imagemBytes = null;
                    }),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remover imagem',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Video passo a passo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_library_outlined),
                    label: const Text('Selecionar video do dispositivo'),
                  ),
                ),
                if (_videoLocalPath != null && _videoLocalPath!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() {
                      _videoLocalPath = null;
                    }),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remover video',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (_videoLocalPath != null && _videoLocalPath!.isNotEmpty)
              Text('Video selecionado: ${p.basename(_videoLocalPath!)}')
            else
              const Text('Sem video cadastrado.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isPreviewingVideo ? null : _previewVideo,
              icon: const Icon(Icons.ondemand_video_outlined),
              label: Text(
                _isPreviewingVideo
                    ? 'Preparando pre-visualizacao...'
                    : 'Pre-visualizar video',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingredientes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _addIngrediente,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._ingredientes.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: item.nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Ingrediente',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: item.quantidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _ingredientes.length == 1
                          ? null
                          : () => _removeIngrediente(index),
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Remover ingrediente',
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              'Modo de preparo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (!_editorReady)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              RepaintBoundary(
                child: quill.QuillSimpleToolbar(
                  controller: _modoPreparoController,
                  config: const quill.QuillSimpleToolbarConfig(
                    multiRowsDisplay: false,
                    showAlignmentButtons: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showListBullets: true,
                    showListNumbers: true,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: false,
                    showInlineCode: false,
                    showCodeBlock: false,
                    showLink: false,
                    showQuote: true,
                    showSubscript: false,
                    showSuperscript: false,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: Container(
                  height: 220,
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
                      placeholder: 'Descreva o modo de preparo...',
                      scrollable: true,
                      autoFocus: false,
                      expands: false,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Salvando...' : 'Salvar ficha tecnica'),
            ),
          ],
        ),
      ),
    );
  }

  quill.Document _buildModoPreparoDocument(String? sourceJson) {
    if (sourceJson == null || sourceJson.isEmpty) {
      return quill.Document();
    }

    try {
      final data = jsonDecode(sourceJson) as List<dynamic>;
      return quill.Document.fromJson(data);
    } catch (_) {
      return quill.Document()..insert(0, sourceJson);
    }
  }

  Uint8List? _decodeImage(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  void _addIngrediente() {
    setState(() {
      _ingredientes.add(_IngredienteInput());
    });
  }

  void _removeIngrediente(int index) {
    final removed = _ingredientes.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _imagemBytes = bytes;
      _imagemBase64 = base64Encode(bytes);
    });
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final selectedPath = result.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel acessar o video.')),
      );
      return;
    }

    setState(() {
      _videoLocalPath = selectedPath;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ingredientes = <FichaTecnicaIngredienteEntity>[];
    for (final item in _ingredientes) {
      final nome = item.nomeController.text.trim();
      final quantidade = item.quantidadeController.text.trim();

      if (nome.isEmpty && quantidade.isEmpty) {
        continue;
      }

      if (nome.isEmpty || quantidade.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preencha nome e quantidade para cada ingrediente.'),
          ),
        );
        return;
      }

      ingredientes.add(
        FichaTecnicaIngredienteEntity(nome: nome, quantidade: quantidade),
      );
    }

    final modoPreparoJson = jsonEncode(
      _modoPreparoController.document.toDelta().toJson(),
    );

    setState(() {
      _isSaving = true;
    });

    final ficha = FichaTecnicaEntity(
      nomeProduto: _nomeController.text.trim().toUpperCase(),
      imagemProdutoBase64: _imagemBase64,
      ingredientes: ingredientes,
      modoPreparoJson: modoPreparoJson,
      videoDriveUrl: null,
      videoLocalPath: _videoLocalPath,
    );

    if (_isEditing) {
      context.read<FichaTecnicaBloc>().add(
        FichaTecnicaUpdated(id: widget.ficha!.id, ficha: ficha),
      );
    } else {
      context.read<FichaTecnicaBloc>().add(FichaTecnicaCreated(ficha: ficha));
    }

    if (!mounted) return;
    context.pop(true);
  }

  Future<bool> _localVideoExists(String? path) async {
    if (path == null || path.isEmpty) return false;
    return File(path).exists();
  }

  Future<void> _previewVideo() async {
    final previewPath = _videoLocalPath;
    if (previewPath == null || previewPath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um video do dispositivo primeiro.'),
        ),
      );
      return;
    }

    final exists = await _localVideoExists(previewPath);
    if (!exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video selecionado nao foi encontrado.')),
      );
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _VideoPreviewDialog(videoPath: previewPath),
    );
  }
}

class _VideoPreviewDialog extends StatefulWidget {
  const _VideoPreviewDialog({required this.videoPath});

  final String videoPath;

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
  VideoPlayerController? _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pre-visualizacao do video',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null)
              Text(_errorMessage!)
            else if (controller == null || !controller.value.isInitialized)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      });
                    },
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initPlayer() async {
    if (kIsWeb) {
      setState(() {
        _errorMessage =
            'Pre-visualizacao local de video nao e suportada no Web.';
      });
      return;
    }

    final file = File(widget.videoPath);
    if (!await file.exists()) {
      setState(() {
        _errorMessage = 'Arquivo de video nao encontrado.';
      });
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao foi possivel carregar o video para pre-visualizacao.';
      });
    }
  }
}

class _IngredienteInput {
  _IngredienteInput({String nome = '', String quantidade = ''})
    : nomeController = TextEditingController(text: nome),
      quantidadeController = TextEditingController(text: quantidade);

  final TextEditingController nomeController;
  final TextEditingController quantidadeController;

  void dispose() {
    nomeController.dispose();
    quantidadeController.dispose();
  }
}

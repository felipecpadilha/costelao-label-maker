import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

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
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _isLoadingVideo = false;
  String? _videoError;

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
    _initVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _modoPreparoController.dispose();
    super.dispose();
  }

  bool get _hasVideoSource {
    final localPath = widget.ficha.videoLocalPath ?? '';
    return localPath.isNotEmpty;
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
          Text(
            'Video passo a passo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildVideoSection(),
          const SizedBox(height: 24),
          _buildIngredientesEModoPreparoSection(context),
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

  Future<void> _initVideo() async {
    final localPath = widget.ficha.videoLocalPath;
    if (localPath == null || localPath.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingVideo = true;
      });
    }

    if (kIsWeb) {
      setState(() {
        _videoError = 'Video local nao e suportado na versao Web.';
        _isLoadingVideo = false;
      });
      return;
    }

    final videoFile = File(localPath);
    if (await videoFile.exists()) {
      final initialized = await _initializeController(
        VideoPlayerController.file(videoFile),
      );
      if (initialized) {
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _videoError = 'Video cadastrado, mas nao foi possivel carregar.';
      _isLoadingVideo = false;
    });
  }

  Future<bool> _initializeController(VideoPlayerController controller) async {
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return false;
      }

      setState(() {
        _videoController = controller;
        _videoReady = true;
        _videoError = null;
        _isLoadingVideo = false;
      });

      return true;
    } catch (_) {
      await controller.dispose();
      return false;
    }
  }

  Widget _buildVideoSection() {
    if (_videoError != null) {
      return _buildVideoUnavailableSection(_videoError!);
    }

    if (_isLoadingVideo) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_videoController == null) {
      return _hasVideoSource
          ? _buildVideoUnavailableSection(
              'Video cadastrado, mas nao carregado.',
            )
          : const Text('Sem video cadastrado.');
    }

    final controller = _videoController!;
    if (!_videoReady) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
    );
  }

  Widget _buildVideoUnavailableSection(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        if (_hasVideoSource) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isLoadingVideo ? null : _retryVideoLoad,
            icon: const Icon(Icons.download_for_offline_outlined),
            label: const Text('Tentar carregar novamente'),
          ),
        ],
      ],
    );
  }

  Widget _buildIngredientesSection(BuildContext context) {
    if (widget.ficha.ingredientes.isEmpty) {
      return const Text('Nenhum ingrediente informado.');
    }

    final isCompactLayout = MediaQuery.of(context).size.width < 640;
    if (isCompactLayout) {
      return Column(
        children: widget.ficha.ingredientes
            .map(
              (ingrediente) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          ingrediente.quantidade,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: Text(
                          ingrediente.nome,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return Card(
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
    );
  }

  Widget _buildIngredientesEModoPreparoSection(BuildContext context) {
    final isTabletLayout = MediaQuery.of(context).size.width >= 900;
    if (!isTabletLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ingredientes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildIngredientesSection(context),
          const SizedBox(height: 24),
          Text(
            'Modo de preparo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildModoPreparoContainer(context),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionBlock(
          context,
          title: 'Ingredientes',
          child: _buildIngredientesSection(context),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSectionBlock(
            context,
            title: 'Modo de preparo',
            child: _buildModoPreparoContainer(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionBlock(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildModoPreparoContainer(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
    );
  }

  Future<void> _retryVideoLoad() async {
    final previousController = _videoController;
    _videoController = null;
    _videoReady = false;
    _videoError = null;
    setState(() {
      _isLoadingVideo = true;
    });

    await previousController?.dispose();
    await _initVideo();
  }
}

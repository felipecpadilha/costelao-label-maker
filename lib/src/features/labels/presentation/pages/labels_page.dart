import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/label_bloc.dart';
import '../bloc/label_event.dart';
import '../bloc/label_state.dart';

class LabelsPage extends StatefulWidget {
  const LabelsPage({super.key});

  @override
  State<LabelsPage> createState() => _LabelsPageState();
}

class _LabelsPageState extends State<LabelsPage> {
  @override
  void initState() {
    super.initState();
    context.read<LabelBloc>().add(const LabelsStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Costelao Label Maker')),
      body: BlocBuilder<LabelBloc, LabelState>(
        builder: (context, state) {
          if (state.status == LabelStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == LabelStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'Erro desconhecido.'),
            );
          }

          if (state.labels.isEmpty) {
            return const Center(child: Text('Nenhuma etiqueta criada ainda.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.labels.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final label = state.labels[index];
              return Card(
                child: ListTile(
                  title: Text(label.name),
                  subtitle: Text(
                    'Tamanho: ${label.width.toStringAsFixed(1)} x ${label.height.toStringAsFixed(1)} mm',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      context.read<LabelBloc>().add(LabelDeleted(label.id));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova etiqueta'),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    var name = '';
    var widthText = '';
    var heightText = '';

    final result = await showDialog<_LabelDialogResult>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Criar etiqueta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: '',
                onChanged: (value) => name = value,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextFormField(
                initialValue: '',
                onChanged: (value) => widthText = value,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Largura (mm)'),
              ),
              TextFormField(
                initialValue: '',
                onChanged: (value) => heightText = value,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Altura (mm)'),
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
                final nameFinal = name.trim();
                final width = double.tryParse(widthText.replaceAll(',', '.'));
                final height = double.tryParse(heightText.replaceAll(',', '.'));

                if (nameFinal.isEmpty || width == null || height == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preencha nome, largura e altura validos.'),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _LabelDialogResult(
                    name: nameFinal,
                    width: width,
                    height: height,
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

    context.read<LabelBloc>().add(
      LabelAdded(name: result.name, width: result.width, height: result.height),
    );
  }
}

class _LabelDialogResult {
  const _LabelDialogResult({
    required this.name,
    required this.width,
    required this.height,
  });

  final String name;
  final double width;
  final double height;
}

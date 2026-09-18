import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../fichas_tecnicas/presentation/bloc/ficha_tecnica_bloc.dart';
import '../../../fichas_tecnicas/presentation/bloc/ficha_tecnica_event.dart';
import '../../../products/presentation/bloc/product_bloc.dart';
import '../../../products/presentation/bloc/product_event.dart';
import '../../../responsaveis/presentation/bloc/responsavel_bloc.dart';
import '../../../responsaveis/presentation/bloc/responsavel_event.dart';
import '../../data/database_backup_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseBackupService _backupService = DatabaseBackupService();
  bool _isExporting = false;
  bool _isImporting = false;
  bool _useFixedFileName = true;
  bool _overwriteFixedFile = true;
  BackupFileInfo? _latestBackup;
  bool _isLoadingBackupInfo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadLatestBackupInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuracoes'),
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Fazer backup do banco (JSON)'),
              subtitle: const Text(
                'Salvar arquivo de backup na pasta Downloads.',
              ),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isExporting || _isImporting ? null : _exportBackup,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _useFixedFileName,
            title: const Text('Usar nome fixo de arquivo'),
            subtitle: const Text('Arquivo: label_maker_backup_latest.json'),
            onChanged: _isExporting || _isImporting
                ? null
                : (value) {
                    setState(() {
                      _useFixedFileName = value;
                    });
                  },
          ),
          SwitchListTile(
            value: _overwriteFixedFile,
            title: const Text('Sobrescrever arquivo fixo'),
            subtitle: const Text(
              'Se desligado, impede substituir backup existente.',
            ),
            onChanged: _isExporting || _isImporting || !_useFixedFileName
                ? null
                : (value) {
                    setState(() {
                      _overwriteFixedFile = value;
                    });
                  },
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('Ultimo backup encontrado'),
              subtitle: _isLoadingBackupInfo
                  ? const Text('Carregando...')
                  : Text(_buildLatestBackupText()),
              trailing: IconButton(
                onPressed: _isLoadingBackupInfo ? null : _loadLatestBackupInfo,
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Recuperar backup (JSON)'),
              subtitle: const Text(
                'Selecionar arquivo JSON e restaurar dados.',
              ),
              trailing: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isExporting || _isImporting ? null : _importBackup,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'A restauracao substitui os dados atuais de produtos, responsaveis e fichas tecnicas.',
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final hasPermission = await _backupService
          .requestSaveToDownloadsPermission();
      if (!hasPermission) {
        if (!mounted) return;
        await _showDownloadsPermissionDeniedDialog();
        return;
      }

      final filePath = await _backupService.exportBackupToDownloads(
        useFixedFileName: _useFixedFileName,
        overwriteFixedFile: _overwriteFixedFile,
      );
      if (!mounted) return;
      await _loadLatestBackupInfo();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup salvo em: $filePath')));
    } on BackupException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao exportar backup.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _importBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar restauracao'),
          content: const Text(
            'A restauracao vai substituir os dados atuais. Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isImporting = true;
    });

    try {
      await _backupService.restoreBackupFromJsonFile();
      if (!mounted) return;

      context.read<ProductBloc>().add(const ProductsStarted());
      context.read<ResponsavelBloc>().add(const ResponsaveisStarted());
      context.read<FichaTecnicaBloc>().add(const FichasTecnicasStarted());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restaurado com sucesso.')),
      );
    } on BackupCanceledException {
      // No-op when user cancels file picker.
    } on BackupException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao restaurar backup.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _loadLatestBackupInfo() async {
    setState(() {
      _isLoadingBackupInfo = true;
    });

    try {
      final info = await _backupService.getLatestBackupInfo();
      if (!mounted) return;
      setState(() {
        _latestBackup = info;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _latestBackup = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBackupInfo = false;
        });
      }
    }
  }

  String _buildLatestBackupText() {
    final info = _latestBackup;
    if (info == null) {
      return 'Nenhum arquivo de backup localizado em Downloads.';
    }

    final dt = info.modifiedAt;
    final data =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final sizeKb = (info.sizeBytes / 1024).toStringAsFixed(1);
    return '${info.fileName}\n$data - $sizeKb KB';
  }

  Future<void> _showDownloadsPermissionDeniedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permissao necessaria'),
          content: const Text(
            'Para salvar backup na pasta Downloads, permita o acesso a arquivos do dispositivo nas configuracoes do app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Abrir configuracoes'),
            ),
          ],
        );
      },
    );
  }
}

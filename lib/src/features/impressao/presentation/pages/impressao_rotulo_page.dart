import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/tspl_bluetooth_printer_service.dart';

class ImpressaoRotuloPage extends StatefulWidget {
  const ImpressaoRotuloPage({super.key});

  @override
  State<ImpressaoRotuloPage> createState() => _ImpressaoRotuloPageState();
}

class _ImpressaoRotuloPageState extends State<ImpressaoRotuloPage> {
  final TsplBluetoothPrinterService _printerService =
      createTsplBluetoothPrinterService();
  final TextEditingController _textoController = TextEditingController();

  List<PrinterDevice> _pairedPrinters = const [];
  String? _selectedPrinterMac;
  bool _isLoadingPrinters = false;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadPairedPrinters();
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Imprimir rotulo'),
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
            TextField(
              controller: _textoController,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Texto do rotulo',
                hintText: 'Digite o texto que deve ser impresso no centro.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Impressora Bluetooth'),
                TextButton.icon(
                  onPressed: _isLoadingPrinters ? null : _loadPairedPrinters,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                ),
              ],
            ),
            if (_isLoadingPrinters) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedPrinterMac ?? 'no-printer'),
              initialValue: _selectedPrinterMac,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Selecionar impressora',
                border: OutlineInputBorder(),
              ),
              items: _pairedPrinters
                  .map(
                    (printer) => DropdownMenuItem<String>(
                      value: printer.macAddress,
                      child: Text(
                        '${printer.name} (${printer.macAddress})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (context) => _pairedPrinters
                  .map(
                    (printer) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${printer.name} (${printer.macAddress})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _pairedPrinters.isNotEmpty
                  ? (value) {
                      setState(() {
                        _selectedPrinterMac = value;
                      });
                    }
                  : null,
            ),
            if (_pairedPrinters.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Nenhuma impressora pareada encontrada. Pareie no Android e toque em Atualizar.',
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isPrinting ? null : _imprimir,
              icon: const Icon(Icons.print_outlined),
              label: Text(_isPrinting ? 'Imprimindo...' : 'Imprimir rotulo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPairedPrinters() async {
    setState(() {
      _isLoadingPrinters = true;
    });

    try {
      final printers = await _printerService.getPairedPrinters();
      if (!mounted) return;

      setState(() {
        _pairedPrinters = printers;
        if (printers.isEmpty) {
          _selectedPrinterMac = null;
          return;
        }

        final selectedExists = printers.any(
          (item) => item.macAddress == _selectedPrinterMac,
        );
        _selectedPrinterMac = selectedExists
            ? _selectedPrinterMac
            : printers.first.macAddress;
      });
    } on TsplPrinterException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel listar as impressoras Bluetooth.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPrinters = false;
        });
      }
    }
  }

  Future<void> _imprimir() async {
    final text = _textoController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um texto para o rotulo.')),
      );
      return;
    }

    final printerMac = _selectedPrinterMac;
    if (printerMac == null || printerMac.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma impressora Bluetooth.')),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      await _printerService.printCustomTextLabel(
        printerMacAddress: printerMac,
        text: text,
        quantity: 1,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impressao enviada com sucesso.')),
      );
    } on TsplPrinterException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao imprimir rotulo.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }
}

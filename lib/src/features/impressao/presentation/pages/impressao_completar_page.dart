import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/tspl_bluetooth_printer_service.dart';
import '../../../products/domain/models/product.dart';
import '../../../responsaveis/domain/models/responsavel.dart';
import '../../../responsaveis/presentation/bloc/responsavel_bloc.dart';
import '../../../responsaveis/presentation/bloc/responsavel_event.dart';
import '../../../responsaveis/presentation/bloc/responsavel_state.dart';

class ImpressaoCompletarPage extends StatefulWidget {
  const ImpressaoCompletarPage({required this.product, super.key});

  final Product product;

  @override
  State<ImpressaoCompletarPage> createState() => _ImpressaoCompletarPageState();
}

class _ImpressaoCompletarPageState extends State<ImpressaoCompletarPage> {
  final TsplBluetoothPrinterService _printerService =
      createTsplBluetoothPrinterService();
  late final TextEditingController _quantidadeController;
  List<PrinterDevice> _pairedPrinters = const [];
  int _quantidade = 1;
  int? _selectedResponsavelId;
  String? _selectedPrinterMac;
  bool _isLoadingPrinters = false;
  bool _isPrinting = false;
  DateTime? _dataValidadeSelecionada;

  @override
  void initState() {
    super.initState();
    _quantidadeController = TextEditingController(text: _quantidade.toString());
    context.read<ResponsavelBloc>().add(const ResponsaveisStarted());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPairedPrinters();
    });
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
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
          title: const Text('Completar impressao'),
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
            final hasResponsaveis = state.responsaveis.isNotEmpty;
            if (hasResponsaveis &&
                !_containsResponsavel(
                  state.responsaveis,
                  _selectedResponsavelId,
                )) {
              _selectedResponsavelId = state.responsaveis.first.id;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text(widget.product.nome),
                    subtitle: Text(
                      widget.product.vencimentoDinamico
                          ? 'Vencimento dinamico'
                          : 'Validade: ${widget.product.tempoDeValidade} dia(s)',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (state.status == ResponsavelStatus.loading)
                  const LinearProgressIndicator(),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  key: ValueKey(_selectedResponsavelId ?? -1),
                  initialValue: _selectedResponsavelId,
                  decoration: const InputDecoration(
                    labelText: 'Responsavel',
                    border: OutlineInputBorder(),
                  ),
                  items: state.responsaveis
                      .map(
                        (responsavel) => DropdownMenuItem<int>(
                          value: responsavel.id,
                          child: Text(responsavel.nome),
                        ),
                      )
                      .toList(),
                  onChanged: hasResponsaveis
                      ? (value) {
                          setState(() {
                            _selectedResponsavelId = value;
                          });
                        }
                      : null,
                ),
                if (!hasResponsaveis)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Cadastre ao menos um responsavel para continuar.',
                    ),
                  ),
                const SizedBox(height: 24),
                TextField(
                  controller: _quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de impressoes',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onQuantidadeChanged,
                ),
                if (widget.product.vencimentoDinamico) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selecionarDataValidade,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de validade',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dataValidadeSelecionada == null
                                ? 'Selecionar data'
                                : _formatarData(_dataValidadeSelecionada!),
                          ),
                          const Icon(Icons.calendar_month_outlined),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Impressora Bluetooth'),
                    TextButton.icon(
                      onPressed: _isLoadingPrinters
                          ? null
                          : _loadPairedPrinters,
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
                  onPressed: hasResponsaveis && !_isPrinting
                      ? _confirmarImpressao
                      : null,
                  icon: const Icon(Icons.print_outlined),
                  label: Text(
                    _isPrinting ? 'Imprimindo...' : 'Confirmar impressao',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onQuantidadeChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 1) {
      return;
    }

    _quantidade = parsed;
  }

  bool _containsResponsavel(List<Responsavel> responsaveis, int? id) {
    if (id == null) return false;
    return responsaveis.any((item) => item.id == id);
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

  Future<void> _confirmarImpressao() async {
    final quantidade = int.tryParse(_quantidadeController.text) ?? _quantidade;
    if (quantidade < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A quantidade precisa ser maior que zero.'),
        ),
      );
      return;
    }

    final selectedId = _selectedResponsavelId;
    if (selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um responsavel.')),
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

    final responsaveis = context.read<ResponsavelBloc>().state.responsaveis;
    final responsavelIndex = responsaveis.indexWhere(
      (item) => item.id == selectedId,
    );

    if (responsavelIndex < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Responsavel invalido.')));
      return;
    }

    final responsavel = responsaveis[responsavelIndex];

    DateTime dataValidade;
    if (widget.product.vencimentoDinamico) {
      final selectedDate = _dataValidadeSelecionada;
      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione a data de validade.')),
        );
        return;
      }
      dataValidade = selectedDate;
    } else {
      dataValidade = DateTime.now().add(
        Duration(days: widget.product.tempoDeValidade),
      );
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      await _printerService.printLabel(
        printerMacAddress: printerMac,
        productName: widget.product.nome,
        responsavelName: responsavel.nome,
        dataValidade: dataValidade,
        quantity: quantidade,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impressao enviada para ${widget.product.nome} ($quantidade copia(s)).',
          ),
        ),
      );
    } on TsplPrinterException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao imprimir etiqueta.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  Future<void> _selecionarDataValidade() async {
    final now = DateTime.now();
    final initialDate = _dataValidadeSelecionada ?? now;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );

    if (!mounted || selectedDate == null) return;

    setState(() {
      _dataValidadeSelecionada = selectedDate;
    });
  }

  String _formatarData(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

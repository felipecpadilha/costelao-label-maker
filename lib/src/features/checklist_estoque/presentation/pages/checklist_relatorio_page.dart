import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/models/checklist_relatorio.dart';

class ChecklistRelatorioPage extends StatelessWidget {
  const ChecklistRelatorioPage({super.key, required this.relatorio});

  final ChecklistRelatorio relatorio;

  @override
  Widget build(BuildContext context) {
    final sections =
        [
          _SectionData(title: 'Itens para comprar', key: 'itensParaComprar'),
          _SectionData(
            title: 'Itens não contabilizados',
            key: 'itensNaoContabilizados',
          ),
        ].where((section) {
          final items =
              relatorio.secoes[section.key] ?? const <ChecklistItem>[];
          return items.isNotEmpty;
        }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Relatório de estoque')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Gerado em: ${relatorio.dataGeracao.toLocal().toString()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (sections.isEmpty)
              const Text('Nenhum item classificado no relatório.')
            else
              for (final section in sections) ...[
                _ReportSection(
                  title: section.title,
                  items:
                      relatorio.secoes[section.key] ?? const <ChecklistItem>[],
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'share-checklist',
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text: relatorio.toShareText(),
                subject: 'Relatório de estoque',
              ),
            ),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Compartilhar'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'pdf-checklist',
            onPressed: () => _exportPdf(),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          final content = <pw.Widget>[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey900,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Relatório de estoque',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Gerado em: ${_formatDateTime(relatorio.dataGeracao.toLocal())}',
                    style: const pw.TextStyle(
                      color: PdfColors.blueGrey100,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
          ];

          final sections = [
            (
              'Itens para comprar',
              relatorio.secoes['itensParaComprar'] ?? const <ChecklistItem>[],
            ),
            (
              'Itens não contabilizados',
              relatorio.secoes['itensNaoContabilizados'] ??
                  const <ChecklistItem>[],
            ),
          ];

          for (final section in sections) {
            if (section.$2.isEmpty) continue;
            content.add(_buildPdfSection(section.$1, section.$2));
            content.add(pw.SizedBox(height: 10));
          }

          if (content.length <= 2) {
            content.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blueGrey200),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text('Nenhum item classificado no relatório.'),
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: content,
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/relatorio_estoque_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Relatório de estoque'),
    );
  }

  pw.Widget _buildPdfSection(String title, List<ChecklistItem> items) {
    final grouped = relatorio.groupBySupplier(items);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: PdfColors.blueGrey900,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          for (final supplierEntry in grouped.entries) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'Fornecedor: ${supplierEntry.key}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                  fontSize: 10,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.blueGrey100),
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey50,
                  ),
                  children: [
                    _pdfCell('Item', isHeader: true),
                    _pdfCell('Qtd comprar', isHeader: true),
                  ],
                ),
                ...supplierEntry.value.map(
                  (item) => pw.TableRow(
                    children: [
                      _pdfCell(item.produtoNome),
                      _pdfCell(item.quantidadeRecomendadaCompra.toString()),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _SectionData {
  const _SectionData({required this.title, required this.key});

  final String title;
  final String key;
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.items});

  final String title;
  final List<ChecklistItem> items;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ChecklistItem>>{};
    for (final item in items) {
      grouped
          .putIfAbsent(item.fornecedorLabel, () => <ChecklistItem>[])
          .add(item);
    }

    final suppliers = grouped.keys.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('Nenhum item para esta seção.')
            else
              for (final supplier in suppliers) ...[
                Text(
                  supplier,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                for (final item in grouped[supplier]!) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    // decoration: BoxDecoration(
                    //   color: Colors.blueGrey.withValues(alpha: 0.06),
                    //   borderRadius: BorderRadius.circular(10),
                    //   border: Border.all(
                    //     color: Colors.blueGrey.withValues(alpha: 0.18),
                    //   ),
                    // ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${item.produtoNome.toUpperCase()}:',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${item.quantidadeRecomendadaCompra}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Qtd atual: ${item.quantidadeAtual ?? 'não preenchido'}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

import 'dart:collection';

class ChecklistItem {
  ChecklistItem({
    required this.produtoNome,
    required this.fornecedorNome,
    this.fornecedorTelefone,
    required this.quantidadeAtual,
    required this.estoqueMinimo,
    required this.estoqueRecomendado,
  }) : quantidadeRecomendadaCompra = quantidadeAtual == null
           ? estoqueRecomendado
           : (estoqueRecomendado - quantidadeAtual).clamp(0, 999999999);

  final String produtoNome;
  final String fornecedorNome;
  final String? fornecedorTelefone;
  final int? quantidadeAtual;
  final int estoqueMinimo;
  final int estoqueRecomendado;
  final int quantidadeRecomendadaCompra;

  String get fornecedorLabel {
    final telefone = fornecedorTelefone?.trim();
    if (telefone == null || telefone.isEmpty) {
      return fornecedorNome;
    }
    return '$fornecedorNome ($telefone)';
  }
}

class ChecklistRelatorio {
  const ChecklistRelatorio({required this.dataGeracao, required this.secoes});

  final DateTime dataGeracao;
  final Map<String, List<ChecklistItem>> secoes;

  Map<String, List<ChecklistItem>> groupBySupplier(List<ChecklistItem> items) {
    final grouped = SplayTreeMap<String, List<ChecklistItem>>();
    for (final item in items) {
      grouped
          .putIfAbsent(item.fornecedorLabel, () => <ChecklistItem>[])
          .add(item);
    }
    return grouped;
  }

  String toShareText() {
    final buffer = StringBuffer();
    buffer.writeln('RELATÓRIO DE CHECKLIST DE ESTOQUE');
    buffer.writeln('Gerado em: ${dataGeracao.toLocal().toString()}');
    buffer.writeln();

    final sectionTitles = {
      'itensParaComprar': 'Itens para comprar',
      'itensNaoContabilizados': 'Itens não contabilizados',
    };

    for (final entry in sectionTitles.entries) {
      final items = secoes[entry.key] ?? const <ChecklistItem>[];
      if (items.isEmpty) continue;

      buffer.writeln('### ${entry.value}');
      final grouped = groupBySupplier(items);
      for (final supplierEntry in grouped.entries) {
        buffer.writeln('- Fornecedor: ${supplierEntry.key}');
        for (final item in supplierEntry.value) {
          buffer.writeln(
            '  • ${item.produtoNome}: ${item.quantidadeRecomendadaCompra}',
          );
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}

class ChecklistRelatorioGenerator {
  static ChecklistRelatorio generate(List<ChecklistItem> items) {
    final paraComprar = <ChecklistItem>[];
    final naoContabilizados = <ChecklistItem>[];

    for (final item in items) {
      final quantidadeAtual = item.quantidadeAtual;
      if (quantidadeAtual == null) {
        naoContabilizados.add(item);
        continue;
      }

      if (quantidadeAtual < item.estoqueMinimo) {
        paraComprar.add(item);
        continue;
      }

      if (quantidadeAtual < item.estoqueRecomendado) {
        paraComprar.add(item);
      }
    }

    final grouped = {
      'itensParaComprar': paraComprar
        ..sort((a, b) => a.fornecedorNome.compareTo(b.fornecedorNome)),
      'itensNaoContabilizados': naoContabilizados
        ..sort((a, b) => a.fornecedorNome.compareTo(b.fornecedorNome)),
    };

    return ChecklistRelatorio(dataGeracao: DateTime.now(), secoes: grouped);
  }
}

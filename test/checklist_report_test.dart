import 'package:flutter_test/flutter_test.dart';

import 'package:costelaolabelmaker/src/features/checklist_estoque/domain/models/checklist_relatorio.dart';

void main() {
  test(
    'gera relatorio agrupado por fornecedor e com quantidade recomendada',
    () {
      final relatorio = ChecklistRelatorioGenerator.generate([
        ChecklistItem(
          produtoNome: 'Arroz',
          fornecedorNome: 'Fornecedor A',
          quantidadeAtual: 3,
          estoqueMinimo: 5,
          estoqueRecomendado: 10,
        ),
        ChecklistItem(
          produtoNome: 'Feijao',
          fornecedorNome: 'Fornecedor A',
          quantidadeAtual: 8,
          estoqueMinimo: 5,
          estoqueRecomendado: 10,
        ),
        ChecklistItem(
          produtoNome: 'Leite',
          fornecedorNome: 'Fornecedor B',
          quantidadeAtual: null,
          estoqueMinimo: 4,
          estoqueRecomendado: 8,
        ),
      ]);

      expect(relatorio.dataGeracao, isNotNull);
      expect(relatorio.secoes['itensParaComprar']!.length, 2);
      expect(relatorio.secoes['itensNaoContabilizados']!.length, 1);

      final itensParaComprar = relatorio.secoes['itensParaComprar']!;
      expect(itensParaComprar[0].produtoNome, 'Arroz');
      expect(itensParaComprar[0].quantidadeRecomendadaCompra, 7);

      expect(itensParaComprar[1].produtoNome, 'Feijao');
      expect(itensParaComprar[1].quantidadeRecomendadaCompra, 2);

      final itemNaoContabilizado =
          relatorio.secoes['itensNaoContabilizados']!.first;
      expect(itemNaoContabilizado.produtoNome, 'Leite');
      expect(itemNaoContabilizado.quantidadeAtual, isNull);
    },
  );
}

import 'package:costelaolabelmaker/src/features/fichas_tecnicas/domain/models/ficha_tecnica.dart';
import 'package:costelaolabelmaker/src/features/fichas_tecnicas/presentation/pages/ficha_tecnica_view_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'exibe os dados principais da ficha tecnica em modo visualizacao',
    (tester) async {
      final ficha = FichaTecnica(
        id: 1,
        nomeProduto: 'Coxa de frango',
        imagemProdutoBase64: null,
        modoPreparoJson: '[]',
        videoDriveUrl: null,
        videoLocalPath: null,
        ingredientes: [
          const FichaTecnicaIngrediente(nome: 'Sal', quantidade: '1 colher'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: FichaTecnicaViewPage(ficha: ficha)),
      );

      expect(find.text('Coxa de frango'), findsOneWidget);
      expect(find.text('Ingredientes'), findsOneWidget);
      expect(find.text('Quantidade'), findsOneWidget);
      expect(find.text('Ingrediente'), findsOneWidget);
      expect(find.text('Sal'), findsOneWidget);
      expect(find.text('1 colher'), findsOneWidget);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Costelao Label Maker'),
        actions: [
          IconButton(
            onPressed: () => context.push('/configuracoes'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuracoes',
          ),
          PopupMenuButton<String>(
            tooltip: 'Cadastros',
            icon: const Icon(Icons.add),
            onSelected: (value) {
              switch (value) {
                case '/produtos':
                  context.push('/produtos');
                  break;
                case '/responsaveis':
                  context.push('/responsaveis');
                  break;
                case '/fichas-tecnicas':
                  context.push('/fichas-tecnicas');
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: '/produtos', child: Text('Produtos')),
              PopupMenuItem(
                value: '/responsaveis',
                child: Text('Responsaveis'),
              ),
              PopupMenuItem(
                value: '/fichas-tecnicas',
                child: Text('Fichas tecnicas'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gapSize = 20.0;
              const buttonCount = 3.0;
              final sizeByWidth = (constraints.maxWidth - 48).clamp(
                140.0,
                280.0,
              );
              final sizeByHeight =
                  ((constraints.maxHeight - (gapSize * (buttonCount - 1))) /
                          buttonCount)
                      .clamp(140.0, 320.0);
              final buttonSize =
                  (sizeByWidth < sizeByHeight ? sizeByWidth : sizeByHeight)
                      .toDouble();

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HomeRouteSquareButton(
                      label: 'ETIQUETAS',
                      icon: Icons.print_outlined,
                      size: buttonSize,
                      onPressed: () => context.push('/impressao'),
                    ),
                    const SizedBox(height: 20),
                    _HomeRouteSquareButton(
                      label: 'ROTULO',
                      icon: Icons.label_outline,
                      size: buttonSize,
                      onPressed: () => context.push('/impressao/rotulo'),
                    ),
                    const SizedBox(height: 20),
                    _HomeRouteSquareButton(
                      label: 'RECEITAS',
                      icon: Icons.menu_book_outlined,
                      size: buttonSize,
                      onPressed: () =>
                          context.push('/fichas-tecnicas/visualizar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeRouteSquareButton extends StatelessWidget {
  const _HomeRouteSquareButton({
    required this.label,
    required this.icon,
    required this.size,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: 12),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeRouteCompactButton extends StatelessWidget {
  const _HomeRouteCompactButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 44,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

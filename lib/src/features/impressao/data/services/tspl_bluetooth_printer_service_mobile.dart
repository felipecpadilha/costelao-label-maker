import 'dart:convert';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'tspl_bluetooth_printer_service.dart';

TsplBluetoothPrinterService createTsplBluetoothPrinterService() {
  return const _TsplBluetoothPrinterServiceMobile();
}

class _TsplBluetoothPrinterServiceMobile extends TsplBluetoothPrinterService {
  const _TsplBluetoothPrinterServiceMobile();

  @override
  Future<List<PrinterDevice>> getPairedPrinters() async {
    final hasPermission =
        await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!hasPermission) {
      throw const TsplPrinterException(
        'Permissao Bluetooth negada. Ative as permissoes do app.',
      );
    }

    final bluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!bluetoothEnabled) {
      throw const TsplPrinterException(
        'Bluetooth desligado. Ative e tente novamente.',
      );
    }

    final printers = await PrintBluetoothThermal.pairedBluetooths;
    return printers
        .map(
          (item) => PrinterDevice(name: item.name, macAddress: item.macAdress),
        )
        .toList();
  }

  @override
  Future<void> printLabel({
    required String printerMacAddress,
    required String productName,
    required String responsavelName,
    required DateTime dataValidade,
    required int quantity,
  }) async {
    final isConnected = await PrintBluetoothThermal.connectionStatus;
    if (!isConnected) {
      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: printerMacAddress,
      );
      if (!connected) {
        throw const TsplPrinterException(
          'Nao foi possivel conectar na impressora Bluetooth selecionada.',
        );
      }
    }

    final dataAtual =
        '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';
    final dataValidadeFormatada =
        '${dataValidade.day.toString().padLeft(2, '0')}/${dataValidade.month.toString().padLeft(2, '0')}/${dataValidade.year}';
    final comando = _buildTsplCommand(
      productName: productName,
      responsavelName: responsavelName,
      dataAtual: dataAtual,
      dataValidade: dataValidadeFormatada,
      quantity: quantity,
    );

    final bytes = List<int>.from(ascii.encode(comando));
    final printed = await PrintBluetoothThermal.writeBytes(bytes);
    if (!printed) {
      throw const TsplPrinterException(
        'Falha ao enviar dados para a impressora.',
      );
    }
  }

  @override
  Future<void> printCustomTextLabel({
    required String printerMacAddress,
    required String text,
    required int quantity,
  }) async {
    final isConnected = await PrintBluetoothThermal.connectionStatus;
    if (!isConnected) {
      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: printerMacAddress,
      );
      if (!connected) {
        throw const TsplPrinterException(
          'Nao foi possivel conectar na impressora Bluetooth selecionada.',
        );
      }
    }

    final comando = _buildCustomTextTsplCommand(text: text, quantity: quantity);

    final bytes = List<int>.from(ascii.encode(comando));
    final printed = await PrintBluetoothThermal.writeBytes(bytes);
    if (!printed) {
      throw const TsplPrinterException(
        'Falha ao enviar dados para a impressora.',
      );
    }
  }

  String _buildTsplCommand({
    required String productName,
    required String responsavelName,
    required String dataAtual,
    required String dataValidade,
    required int quantity,
  }) {
    final produto = _sanitizeText(productName);
    final responsavel = _sanitizeText(responsavelName, maxLength: 16);

    // Ajuste gradual de fonte para o produto:
    // curto: 2x2, medio: 2x1, longo: 1x1.
    final produtoXScale = produto.length <= 14
        ? 2
        : produto.length <= 24
        ? 2
        : 1;
    final produtoYScale = produto.length <= 14
        ? 2
        : produto.length <= 24
        ? 1
        : 1;
    final produtoX = _calculateCenteredX(produto, charWidth: 8 * produtoXScale);
    final dataValidadeX = _calculateCenteredX(dataValidade, charWidth: 16);

    return [
      'SIZE 40 mm,30 mm',
      'GAP 2 mm,0 mm',
      'DENSITY 8',
      'SPEED 4',
      'DIRECTION 1',
      'REFERENCE 0,0',
      'CLS',
      'TEXT $produtoX,24,"0",0,$produtoXScale,$produtoYScale,"$produto"',
      'TEXT 12,74,"0",1,1,0,"RESPONSAVEL: $responsavel"',
      'TEXT 12,100,"0",1,1,0,"DATA: $dataAtual"',
      'TEXT 12,126,"0",1,1,0,"VALIDADE:"',
      'TEXT $dataValidadeX,160,"0",0,2,2,"$dataValidade"',
      'REVERSE ${dataValidadeX - 5},155,32,30',
      'PRINT $quantity,1  ',
    ].join('\n');
  }

  int _calculateCenteredX(String text, {required int charWidth}) {
    const labelWidth = 320; // 40 mm em 8 dots/mm
    final textWidth = text.length * charWidth;
    final centered = ((labelWidth - textWidth) / 2).round();
    return centered.clamp(0, labelWidth - charWidth);
  }

  String _buildCustomTextTsplCommand({
    required String text,
    required int quantity,
  }) {
    final normalized = _sanitizeText(text).replaceAll('"', '');
    final lines = _wrapText(normalized, maxCharsPerLine: 14, maxLines: 4);

    const labelHeight = 240; // 30 mm em 8 dots/mm
    const lineHeight = 44;
    const charWidth = 16; // fonte "0" com escala 2x
    final blockHeight = lines.length * lineHeight;
    final startY = ((labelHeight - blockHeight) / 2).round().clamp(12, 170);

    final commands = <String>[
      'SIZE 40 mm,30 mm',
      'GAP 2 mm,0 mm',
      'DENSITY 8',
      'SPEED 4',
      'DIRECTION 1',
      'REFERENCE 0,0',
      'CLS',
    ];

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final x = _calculateCenteredX(line, charWidth: charWidth);
      final y = startY + (index * lineHeight);
      commands.add('TEXT $x,$y,"0",0,2,2,"$line"');
    }

    commands.add('PRINT $quantity,1');
    return commands.join('\n');
  }

  List<String> _wrapText(
    String text, {
    required int maxCharsPerLine,
    required int maxLines,
  }) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return const ['ROTULO'];
    }

    final words = normalized.split(' ');
    final lines = <String>[];
    var current = '';

    for (final rawWord in words) {
      var word = rawWord;
      if (word.length > maxCharsPerLine) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }

        while (word.length > maxCharsPerLine) {
          if (lines.length >= maxLines) {
            return lines;
          }
          lines.add(word.substring(0, maxCharsPerLine));
          word = word.substring(maxCharsPerLine);
        }

        if (word.isEmpty) {
          continue;
        }
      }

      if (current.isEmpty) {
        current = word;
        continue;
      }

      final next = '$current $word';
      if (next.length <= maxCharsPerLine) {
        current = next;
      } else {
        lines.add(current);
        current = word;
      }

      if (lines.length >= maxLines) {
        return lines;
      }
    }

    if (current.isNotEmpty && lines.length < maxLines) {
      lines.add(current);
    }

    return lines.isEmpty ? const ['ROTULO'] : lines;
  }

  String _sanitizeText(String input, {int? maxLength}) {
    final normalized = input
        .trim()
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ã', 'A')
        .replaceAll('Ä', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ë', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Î', 'I')
        .replaceAll('Ï', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ö', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Û', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ç', 'C');

    if (maxLength == null || normalized.length <= maxLength) {
      return normalized;
    }

    return normalized.substring(0, maxLength);
  }
}

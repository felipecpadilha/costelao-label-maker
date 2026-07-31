import 'tspl_bluetooth_printer_service.dart';

TsplBluetoothPrinterService createTsplBluetoothPrinterService() {
  return const _TsplBluetoothPrinterServiceStub();
}

class _TsplBluetoothPrinterServiceStub extends TsplBluetoothPrinterService {
  const _TsplBluetoothPrinterServiceStub();

  @override
  Future<List<PrinterDevice>> getPairedPrinters() {
    throw const TsplPrinterException(
      'Impressao Bluetooth nao suportada nesta plataforma.',
    );
  }

  @override
  Future<void> printLabel({
    required String printerMacAddress,
    required String productName,
    required String responsavelName,
    required DateTime dataValidade,
    required int quantity,
  }) {
    throw const TsplPrinterException(
      'Impressao Bluetooth nao suportada nesta plataforma.',
    );
  }

  @override
  Future<void> printCustomTextLabel({
    required String printerMacAddress,
    required String text,
    required int quantity,
  }) {
    throw const TsplPrinterException(
      'Impressao Bluetooth nao suportada nesta plataforma.',
    );
  }
}

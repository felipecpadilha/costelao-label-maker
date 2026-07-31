import 'tspl_bluetooth_printer_service_stub.dart'
    if (dart.library.io) 'tspl_bluetooth_printer_service_mobile.dart'
    as impl;

abstract class TsplBluetoothPrinterService {
  const TsplBluetoothPrinterService();

  Future<List<PrinterDevice>> getPairedPrinters();

  Future<void> printLabel({
    required String printerMacAddress,
    required String productName,
    required String responsavelName,
    required DateTime dataValidade,
    required int quantity,
  });

  Future<void> printCustomTextLabel({
    required String printerMacAddress,
    required String text,
    required int quantity,
  });
}

class PrinterDevice {
  const PrinterDevice({required this.name, required this.macAddress});

  final String name;
  final String macAddress;
}

TsplBluetoothPrinterService createTsplBluetoothPrinterService() {
  return impl.createTsplBluetoothPrinterService();
}

class TsplPrinterException implements Exception {
  const TsplPrinterException(this.message);

  final String message;

  @override
  String toString() => message;
}

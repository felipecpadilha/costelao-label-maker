import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as sqflite_ffi_web;

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = sqflite_ffi_web.databaseFactoryFfiWeb;
  } else {
    sqflite_ffi.sqfliteFfiInit();
    databaseFactory = sqflite_ffi.databaseFactoryFfi;
  }

  await _requestAndroidBluetoothPermissionsIfNeeded();

  runApp(const LabelMakerApp());
}

Future<void> _requestAndroidBluetoothPermissionsIfNeeded() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  final permissions = <Permission>[
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ];

  for (final permission in permissions) {
    final status = await permission.status;
    if (!status.isGranted && !status.isPermanentlyDenied) {
      await permission.request();
    }
  }
}

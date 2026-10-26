import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});
  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR')),
      body: MobileScanner(
        errorBuilder: (_, e, __) => Center(child: Text('Camera error: ${e.errorCode.name}')),
        onDetect: (capture) {
          if (_done) return;
          final v = capture.barcodes.firstOrNull?.rawValue;
          if (v != null && v.contains('://')) {
            _done = true;
            Navigator.pop(context, v);
          }
        },
      ),
    );
  }
}

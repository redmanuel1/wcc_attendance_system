import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wcc_attendance_system/app_state.dart';
import 'package:wcc_attendance_system/pages/SyncService.dart';
import 'FormPage.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;
  bool? _hasActive;

  @override
  void initState() {
    super.initState();
    _checkActiveTransaction();
  }

  Future<void> _checkActiveTransaction() async {
    final docId = AppState().documentID;
    if (docId == null) {
      setState(() {
        _hasActive = true; // block scanner if no logged-in user
      });
      return;
    }

    final active = await SyncService().hasActiveTransaction(docId);
    setState(() {
      _hasActive = active;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (isProcessing) return;
    isProcessing = true;

    final String? code = capture.barcodes.first.rawValue;
    print("Scanned QR Code: $code");

    if (code == "wcc-rampguard") {
      controller.stop();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FormPage()),
      ).then((_) {
        controller.start();
        isProcessing = false;
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Invalid QR Code'),
            content: const Text('The scanned code is not recognized.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  isProcessing = false;
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasActive == null) {
      return Scaffold(
        backgroundColor: Colors.blue.shade700,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_hasActive == true) {
      return Scaffold(
        backgroundColor: Colors.blue.shade700,
        body: const Center(
          child: Text(
            "You already have a pending transaction.\nPlease sign off before scanning a new one.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: MobileScanner(
                controller: controller,
                onDetect: _onDetect,
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Please scan the QR code',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

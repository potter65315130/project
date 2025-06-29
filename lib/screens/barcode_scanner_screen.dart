import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// หน้าจอสำหรับสแกนบาร์โค้ดโดยเฉพาะ
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isTorchOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับเปิด/ปิดไฟฉาย
  void _toggleTorch() async {
    try {
      await controller.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling torch: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกนบาร์โค้ด'),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.amber : Colors.grey,
            ),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        // เมื่อตรวจพบบาร์โค้ด ให้ปิดหน้าจอนี้และส่งค่าบาร์โค้ดกลับไป
        onDetect: (capture) {
          final barcode = capture.barcodes.first.rawValue;
          if (barcode != null) {
            controller.stop();
            Navigator.of(context).pop(barcode);
          }
        },
      ),
    );
  }
}

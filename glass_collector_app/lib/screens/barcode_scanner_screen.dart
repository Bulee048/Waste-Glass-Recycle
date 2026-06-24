import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Full-screen Code 128 scanner. Pops with the decoded string on success.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController? _controller;
  bool _handled = false;
  // null = checking, true = granted, false = denied
  bool? _permissionGranted;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      final ctrl = MobileScannerController(
        formats: const [BarcodeFormat.code128],
        autoStart: true,
      );
      setState(() {
        _controller = ctrl;
        _permissionGranted = true;
      });
    } else {
      setState(() => _permissionGranted = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      _handled = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  Future<void> _showManualEntryDialog() async {
    final TextEditingController controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Entry'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter barcode (e.g., SUP001)',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty && mounted) {
      Navigator.of(context).pop(value);
    }
  }

  // ─── Views ───────────────────────────────────────────────────────────────

  Widget _buildLoading() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Requesting camera permission…',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );

  Widget _buildPermissionDenied() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  color: Colors.white54, size: 64),
              const SizedBox(height: 24),
              const Text('Camera Permission Required',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'Please allow camera access in your device settings, then come back and try again.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open App Settings'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showManualEntryDialog,
                icon: const Icon(Icons.keyboard, color: Colors.white70),
                label: const Text('Enter Barcode Manually',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );

  Widget _buildScanner() => Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
            errorBuilder: (BuildContext context, MobileScannerException error,
                Widget? child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Camera failed to start.\nCode: ${error.errorCode.name}',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showManualEntryDialog,
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Enter Barcode Manually'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Align the Code 128 barcode within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text('Or tap here to type manually',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Enter Manually',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: switch (_permissionGranted) {
        null  => _buildLoading(),
        false => _buildPermissionDenied(),
        true  => _buildScanner(),
      },
    );
  }
}

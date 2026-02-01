import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';
import 'customer/menu_browser_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isFlashOn = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_isProcessing) return; // Prevent multiple scans

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processQRCode(barcode.rawValue!, context);
                  break; // Process only first barcode
                }
              }
            },
          ),

          // Scanner overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: const Color(0xFF2E8B57), // Success Green
                borderRadius: 20,
                borderLength: 40,
                borderWidth: 8,
                cutOutSize: 280,
              ),
            ),
          ),
          
          // Instructions text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Align QR code within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing QR Code...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: Colors.blue,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }

  Future<void> _processQRCode(String qrData, BuildContext context) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      print('Scanned QR Code: $qrData');

      // Parse restaurant data from QR code
      // Format could be: "restaurant:restaurantId:restaurantName"
      final qrDataParts = qrData.split(':');

      if (qrDataParts.length >= 3 && qrDataParts[0] == 'restaurant') {
        final restaurantId = qrDataParts[1];
        final restaurantName = Uri.decodeComponent(qrDataParts[2]);

        // Get restaurant service using context that's available
        final restaurantService = Provider.of<RestaurantService>(context, listen: false);

        Restaurant? restaurant;

        try {
          // Try to get restaurant from Firestore
          restaurant = await restaurantService.getRestaurantById(restaurantId);
        } catch (e) {
          print('Error fetching restaurant: $e');
        }

        if (restaurant == null) {
          // Create a temporary restaurant object
          restaurant = Restaurant(
            restaurantId: restaurantId,
            ownerId: '', // Empty for temp restaurant
            name: restaurantName,
            address: 'Scanned from QR code',
            contact: '',
            rating: 0.0,
            isActive: true,
            createdAt: DateTime.now(),
          );
        }

        if (context.mounted) {
          setState(() {
            _isProcessing = false;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerMenuScreen(
                restaurantId: restaurantId,
                restaurantName: restaurantName,
              ),
            ),
          );
        }
      } else {
        // Invalid QR code format
        if (context.mounted) {
          setState(() {
            _isProcessing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid QR code format: $qrData'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );

          // Resume scanning after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
            }
          });
        }
      }
    } catch (e) {
      print('Error processing QR code: $e');

      if (context.mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Custom scanner overlay shape
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderRadius = 10,
    this.borderLength = 30,
    this.borderWidth = 5,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(
        Rect.fromCircle(
          center: rect.center,
          radius: cutOutSize / 2,
        ),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(rect)
      ..addPath(getInnerPath(rect), Offset.zero)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final centerX = width / 2;
    final centerY = height / 2;
    final cutOutHalfSize = cutOutSize / 2;

    // Draw border around cutout
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(centerX - cutOutHalfSize, centerY - cutOutHalfSize + borderLength)
        ..lineTo(centerX - cutOutHalfSize, centerY - cutOutHalfSize)
        ..lineTo(centerX - cutOutHalfSize + borderLength, centerY - cutOutHalfSize),
      paint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(centerX + cutOutHalfSize - borderLength, centerY - cutOutHalfSize)
        ..lineTo(centerX + cutOutHalfSize, centerY - cutOutHalfSize)
        ..lineTo(centerX + cutOutHalfSize, centerY - cutOutHalfSize + borderLength),
      paint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(centerX + cutOutHalfSize, centerY + cutOutHalfSize - borderLength)
        ..lineTo(centerX + cutOutHalfSize, centerY + cutOutHalfSize)
        ..lineTo(centerX + cutOutHalfSize - borderLength, centerY + cutOutHalfSize),
      paint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(centerX - cutOutHalfSize + borderLength, centerY + cutOutHalfSize)
        ..lineTo(centerX - cutOutHalfSize, centerY + cutOutHalfSize)
        ..lineTo(centerX - cutOutHalfSize, centerY + cutOutHalfSize - borderLength),
      paint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
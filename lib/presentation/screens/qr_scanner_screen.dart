import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/services/api_service.dart';
import '../../data/services/audio_service.dart';
import '../widgets/scan_mode_menu.dart';
import 'face_detection_screen.dart';

class QrScannerScreen extends StatefulWidget {
  final String mealType;
  final CameraDescription camera;

  const QrScannerScreen({
    Key? key,
    required this.mealType,
    required this.camera,
  }) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.front,
  );
  final _apiService = ApiService();

  bool _isProcessing = false;
  String? _resultMessage;
  bool? _isSuccess;
  String? _studentName;
  String? _studentImage;

  @override
  void initState() {
    super.initState();
    Logger.info('QR Scanner Screen initialized for ${widget.mealType}');
  }

  Future<void> _processQrCode(String qrToken) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    Logger.info('Processing QR token: ${qrToken.substring(0, 10)}...');

    try {
      final result = await _apiService.logMealByQr(
        qrToken,
        widget.mealType,
      );

      if (!mounted) return;

      result.when(
        success: (data) async {
          setState(() {
            _isSuccess = data['success'] as bool? ?? false;
            _resultMessage = data['message'] as String? ?? 'Xatolik';
            _studentName = data['student_name'] as String?;
            _studentImage = data['student_image'] as String?;
          });

          if (_isSuccess == true) {
            await AudioService.playSuccess();
            _showSuccessDialog();
          } else {
            await AudioService.playFailed();
            await Future.delayed(const Duration(seconds: 3));
            if (mounted) {
              setState(() {
                _isSuccess = null;
                _resultMessage = null;
              });
            }
          }
        },
        failure: (error) async {
          setState(() {
            _isSuccess = false;
            _resultMessage = error.message;
          });
          await AudioService.playFailed();

          await Future.delayed(const Duration(seconds: 3));
          if (mounted) {
            setState(() {
              _isSuccess = null;
              _resultMessage = null;
            });
          }
        },
      );
    } catch (e) {
      Logger.error('QR processing error: $e');
      if (mounted) {
        await AudioService.playFailed();
        setState(() {
          _isSuccess = false;
          _resultMessage = 'Xatolik';
        });

        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _isSuccess = null;
            _resultMessage = null;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        studentName: _studentName ?? 'Student',
        studentImage: _studentImage,
        message: _resultMessage ?? 'Muvaffaqiyatli',
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _isSuccess = null;
          _resultMessage = null;
          _studentName = null;
          _studentImage = null;
        });
      }
    });
  }

  void _navigateToFaceScreen() {
    Logger.info('Switching to Face Detection');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FaceDetectionScreen(
          camera: widget.camera,
          mealType: widget.mealType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // QR Scanner (full screen)
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _processQrCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Back button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
              onPressed: () {
                Logger.info('Back button pressed');
                Navigator.pop(context);
              },
            ),
          ),

          // Menu button (Face/QR toggle)
          Positioned(
            top: 40,
            right: 20,
            child: ScanModeMenu(
              currentMode: ScanMode.qr,
              onFaceTap: _navigateToFaceScreen,
              onQrTap: () {},
            ),
          ),

          // Scanner frame overlay
          if (!_isProcessing && _resultMessage == null)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'QR kodni skanerlang',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Processing indicator
          if (_isProcessing && _resultMessage == null)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Result message (Xato uchun)
          if (_resultMessage != null && _isSuccess == false)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _resultMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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

  @override
  void dispose() {
    Logger.info('QR Scanner Screen disposed');
    _scannerController.dispose();
    super.dispose();
  }
}

// Success Dialog Widget
class _SuccessDialog extends StatelessWidget {
  final String studentName;
  final String? studentImage;
  final String message;

  const _SuccessDialog({
    required this.studentName,
    this.studentImage,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Student image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: ClipOval(
                child: studentImage != null && studentImage!.isNotEmpty
                    ? Image.network(
                  studentImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey,
                    );
                  },
                )
                    : const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Success icon
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),

            // Student name
            Text(
              studentName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
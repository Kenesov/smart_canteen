import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );

  runApp(MyApp(camera: frontCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Face Detection',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: FaceDetectionScreen(camera: camera),
    );
  }
}

class FaceDetectionScreen extends StatefulWidget {
  final CameraDescription camera;
  const FaceDetectionScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  bool _cameraInitialized = false;
  bool _isProcessing = false;

  // Face detection state
  Rect? _faceRect;
  bool _shouldShowOverlay = false;
  Size? _imageSize;
  DateTime? _lastCaptureTime;

  // Verification result
  String? _resultMessage;
  bool? _isSuccess;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: false,
      enableClassification: true, // Ko'z ochiq/yopiqligini aniqlash uchun
      enableLandmarks: true,
      enableTracking: false,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;

      setState(() => _cameraInitialized = true);

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && _controller != null) {
        await _controller!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Kamera xatoligi: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _isProcessing) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      if (!mounted) {
        _isDetecting = false;
        return;
      }

      _processFaces(faces, image);
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _processFaces(List<Face> faces, CameraImage image) {
    setState(() {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());

      if (faces.isEmpty || faces.length > 1) {
        _faceRect = null;
        _shouldShowOverlay = false;
        if (faces.isEmpty) {
          print("❌ Face not detected");
        } else {
          print("❌ Multiple faces detected");
        }
      } else {
        final face = faces.first;
        _faceRect = face.boundingBox;

        final qualityResult = _checkFullQuality(face, image);
        _shouldShowOverlay = qualityResult['showOverlay'];

        // Rangni aniqlash
        if (qualityResult['reason'] == 'eyes_closed' ||
            qualityResult['reason'] == 'too_far' ||
            qualityResult['reason'] == 'too_close' ||
            qualityResult['reason'] == 'not_centered' ||
            qualityResult['reason'] == 'head_tilted') {
            print("❌ Wrong face: ${qualityResult['reason']}");
        } else {
          print("✅ Face is correct and ready to capture");
        }

        // Capturega tayyor bo‘lsa
        if (_shouldShowOverlay && qualityResult['readyToCapture'] && _canCapture()) {
          _captureAndSend(image);
          print("📸 Face snapshot sent to backend");
        }
      }
    });
  }

  Map<String, dynamic> _checkFullQuality(Face face, CameraImage image) {
    final boundingBox = face.boundingBox;
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    // 1. Masofa tekshiruvi (0.3m - 1.0m)
    final faceArea = boundingBox.width * boundingBox.height;
    final imageArea = imageWidth * imageHeight;
    final faceRatio = faceArea / imageArea;

    // Masofa: juda kichik = uzoq, juda katta = yaqin
    if (faceRatio < 0.10) {
      return {'showOverlay': false, 'readyToCapture': false, 'reason': 'too_far'};
    }
    if (faceRatio > 0.60) {
      return {'showOverlay': false, 'readyToCapture': false, 'reason': 'too_close'};
    }

    // 2. Markazda ekanligini tekshirish
    final faceCenterX = boundingBox.center.dx;
    final faceCenterY = boundingBox.center.dy;
    final centerThreshold = 0.35;
    final xOffset = (faceCenterX - imageWidth / 2).abs() / imageWidth;
    final yOffset = (faceCenterY - imageHeight / 2).abs() / imageHeight;

    if (xOffset > centerThreshold || yOffset > centerThreshold) {
      return {'showOverlay': false, 'readyToCapture': false, 'reason': 'not_centered'};
    }

    // 3. Bosh burchagi (to'liq ko'rinish)
    final headEulerAngleX = face.headEulerAngleX?.abs() ?? 0;
    final headEulerAngleY = face.headEulerAngleY?.abs() ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ?.abs() ?? 0;

    if (headEulerAngleX > 25 || headEulerAngleY > 30 || headEulerAngleZ > 25) {
      return {'showOverlay': false, 'readyToCapture': false, 'reason': 'head_tilted'};
    }

    // 4. Ko'zlar ochiqmi tekshirish (ENG MUHIM!)
    final leftEyeOpen = face.leftEyeOpenProbability;
    final rightEyeOpen = face.rightEyeOpenProbability;

    // Agar ML Kit ko'z ochiq/yopiqligini aniqlay olmasa
    if (leftEyeOpen == null || rightEyeOpen == null) {
      // Fallback: landmark orqali tekshirish
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];

      if (leftEye == null || rightEye == null) {
        // Ko'z topilmadi - overlay ko'rsatamiz lekin capture qilmaymiz
        return {'showOverlay': true, 'readyToCapture': false, 'reason': 'eyes_not_detected'};
      }
    } else {
      // Ko'z ochiqlik darajasi 0.7 dan past bo'lsa - yopiq deb hisoblaymiz
      if (leftEyeOpen < 0.5 || rightEyeOpen < 0.5) {
        return {'showOverlay': false, 'readyToCapture': false, 'reason': 'eyes_closed'};
      }
    }

    // Barcha shartlar bajarildi!
    return {'showOverlay': true, 'readyToCapture': true, 'reason': 'perfect'};
  }

  bool _canCapture() {
    if (_lastCaptureTime == null) return true;
    return DateTime.now().difference(_lastCaptureTime!) > const Duration(seconds: 3);
  }

  Future<void> _captureAndSend(CameraImage image) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    _lastCaptureTime = DateTime.now();

    try {
      // JPEG yaratish
      final jpegBytes = await _convertToJpeg(image);
      if (jpegBytes == null) throw Exception('JPEG conversion failed');

      // Backend'ga yuborish
      final result = await _sendToBackend(jpegBytes);

      if (!mounted) return;

      setState(() {
        _isSuccess = result['success'];
        _resultMessage = result['success']
            ? 'Muvaffaqiyatli'
            : 'Rad etildi';
      });

      // 2 soniya natijani ko'rsatish
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSuccess = null;
          _resultMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        setState(() {
          _isSuccess = false;
          _resultMessage = 'Xatolik';
        });

        await Future.delayed(const Duration(seconds: 2));

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

  Future<Uint8List?> _convertToJpeg(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;
      final imgLib = img.Image(width: width, height: height);

      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * yPlane.bytesPerRow + x;
          final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);

          final yValue = yPlane.bytes[yIndex];
          final uValue = uPlane.bytes[uvIndex];
          final vValue = vPlane.bytes[uvIndex];

          final r = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
          final g = (yValue - 0.698001 * (vValue - 128) - 0.337633 * (uValue - 128)).round().clamp(0, 255);
          final b = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);

          imgLib.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }

      return Uint8List.fromList(img.encodeJpg(imgLib, quality: 85));
    } catch (e) {
      debugPrint('JPEG conversion error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _sendToBackend(Uint8List imageBytes) async {
    final dio = Dio();

    try {
      const backendUrl = 'https://your-backend-api.com/api/face/verify';

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(imageBytes, filename: 'face.jpg'),
      });

      final response = await dio.post(
        backendUrl,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': response.data['success'] ?? false,
          'name': response.data['student_name'],
        };
      }
      return {'success': false};
    } catch (e) {
      debugPrint('Backend error: $e');
      return {'success': false};
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImageFormat = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _getRotation(widget.camera.sensorOrientation),
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  InputImageRotation _getRotation(int rotation) {
    switch (rotation) {
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen camera
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // Domaloq overlay (faqat shartlar bajarilganda)
          if (_shouldShowOverlay && _faceRect != null && _imageSize != null)
            CustomPaint(
              painter: FaceCircleOverlay(
                faceRect: _faceRect!,
                imageSize: _imageSize!,
                previewSize: _controller!.value.previewSize!,
                cameraLensDirection: widget.camera.lensDirection,
              ),
            ),

          // Natija ko'rsatish (minimal)
          if (_resultMessage != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: (_isSuccess! ? Colors.green : Colors.red).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSuccess! ? Icons.check_circle : Icons.error,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _resultMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }
}

// Domaloq overlay painter
class FaceCircleOverlay extends CustomPainter {
  final Rect faceRect;
  final Size imageSize;
  final Size previewSize;
  final CameraLensDirection cameraLensDirection;

  FaceCircleOverlay({
    required this.faceRect,
    required this.imageSize,
    required this.previewSize,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Koordinatalarni convert qilish
    final scaleX = size.width / imageSize.height;
    final scaleY = size.height / imageSize.width;

    double left, top, right, bottom;

    if (cameraLensDirection == CameraLensDirection.front) {
      // Front camera uchun mirror
      left = size.width - (faceRect.bottom * scaleX);
      top = faceRect.left * scaleY;
      right = size.width - (faceRect.top * scaleX);
      bottom = faceRect.right * scaleY;
    } else {
      left = faceRect.top * scaleX;
      top = faceRect.left * scaleY;
      right = faceRect.bottom * scaleX;
      bottom = faceRect.right * scaleY;
    }

    final rect = Rect.fromLTRB(left, top, right, bottom);
    final center = rect.center;
    final radius = (rect.width > rect.height ? rect.width : rect.height) / 1.8;

    // Doira chizish
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, paint);

    // Ichki shaffof doira
    final innerPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, innerPaint);
  }

  @override
  bool shouldRepaint(FaceCircleOverlay oldDelegate) {
    return oldDelegate.faceRect != faceRect;
  }
}
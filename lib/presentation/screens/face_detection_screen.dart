import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/services/api_service.dart';
import '../../data/services/audio_service.dart';
import '../widgets/face_overlay.dart';

class FaceDetectionScreen extends StatefulWidget {
  final CameraDescription camera;
  final String mealType;

  const FaceDetectionScreen({
    Key? key,
    required this.camera,
    required this.mealType,
  }) : super(key: key);

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  final _apiService = ApiService();

  bool _isDetecting = false;
  bool _cameraInitialized = false;
  bool _isProcessing = false;
  bool _isFaceCorrect = false;

  Rect? _faceRect;
  bool _shouldShowOverlay = false;
  Size? _imageSize;
  DateTime? _lastCaptureTime;

  String? _resultMessage;
  bool? _isSuccess;

  @override
  void initState() {
    super.initState();
    Logger.info('Face Detection Screen initialized');
    _initializeFaceDetector();
    _initializeCamera();
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    Logger.info('Face detector initialized');
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
      Logger.success('Camera initialized');

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && _controller != null) {
        await _controller!.startImageStream(_processCameraImage);
        Logger.info('Image stream started');
      }
    } catch (e) {
      Logger.error('Camera initialization error: $e');
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
      Logger.error('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _processFaces(List<Face> faces, CameraImage image) {
    if (!mounted) return;

    bool faceCorrect = false;
    Rect? faceRect;
    Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    if (faces.isEmpty) {
      Logger.faceDetection('No face detected');
    } else if (faces.length > 1) {
      Logger.faceDetection('Multiple faces detected');
      faceRect = faces.first.boundingBox;
    } else {
      final face = faces.first;
      faceRect = face.boundingBox;

      final qualityResult = _checkFullQuality(face, image);
      faceCorrect = qualityResult['readyToCapture'];

      if (faceCorrect) {
        Logger.faceDetection('Face is correct and ready');
      } else {
        Logger.faceDetection('Wrong face: ${qualityResult['reason']}');
      }

      if (qualityResult['showOverlay'] && faceCorrect && _canCapture()) {
        _captureAndSend();
        Logger.info('Capturing face');
      }
    }

    setState(() {
      _imageSize = imageSize;
      _faceRect = faceRect;
      _shouldShowOverlay = faceRect != null;
      _isFaceCorrect = faceCorrect;
    });
  }

  Map<String, dynamic> _checkFullQuality(Face face, CameraImage image) {
    final boundingBox = face.boundingBox;
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    bool readyToCapture = true;
    String reason = 'perfect';

    // Distance check
    final faceArea = boundingBox.width * boundingBox.height;
    final imageArea = imageWidth * imageHeight;
    final faceRatio = faceArea / imageArea;

    if (faceRatio < AppConstants.minFaceRatio) {
      readyToCapture = false;
      reason = 'too_far';
    } else if (faceRatio > AppConstants.maxFaceRatio) {
      readyToCapture = false;
      reason = 'too_close';
    }

    // Center check
    final faceCenterX = boundingBox.center.dx;
    final faceCenterY = boundingBox.center.dy;
    final xOffset = (faceCenterX - imageWidth / 2).abs() / imageWidth;
    final yOffset = (faceCenterY - imageHeight / 2).abs() / imageHeight;

    if (xOffset > AppConstants.centerThreshold ||
        yOffset > AppConstants.centerThreshold) {
      readyToCapture = false;
      reason = 'not_centered';
    }

    // Head angle check
    final headEulerAngleX = face.headEulerAngleX?.abs() ?? 0;
    final headEulerAngleY = face.headEulerAngleY?.abs() ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ?.abs() ?? 0;

    if (headEulerAngleX > AppConstants.maxHeadAngleX ||
        headEulerAngleY > AppConstants.maxHeadAngleY ||
        headEulerAngleZ > AppConstants.maxHeadAngleZ) {
      readyToCapture = false;
      reason = 'head_tilted';
    }

    // Eye check
    final leftEyeOpen = face.leftEyeOpenProbability;
    final rightEyeOpen = face.rightEyeOpenProbability;

    if (leftEyeOpen != null && rightEyeOpen != null) {
      if (leftEyeOpen < AppConstants.minEyeOpenProbability ||
          rightEyeOpen < AppConstants.minEyeOpenProbability) {
        readyToCapture = false;
        reason = 'eyes_closed';
      }
    }

    return {
      'showOverlay': true,
      'readyToCapture': readyToCapture,
      'reason': reason,
    };
  }

  bool _canCapture() {
    if (_lastCaptureTime == null) return true;
    return DateTime.now().difference(_lastCaptureTime!) >
        AppConstants.captureCooldown;
  }

  Future<void> _captureAndSend() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    _lastCaptureTime = DateTime.now();

    try {
      Logger.info('Capturing image with takePicture');

      final file = await _controller!.takePicture();
      final jpegBytes = await file.readAsBytes();

      Logger.success(
          'Image captured: ${jpegBytes.length} bytes (${(jpegBytes.length / 1024).toStringAsFixed(2)} KB)');

      final result =
      await _apiService.logMealByFace(jpegBytes, widget.mealType);

      if (!mounted) return;

      setState(() {
        _isSuccess = result['success'];
        _resultMessage = result['message'] ?? 'Xatolik';
      });

      // Play sound
      if (result['success'] == true) {
        await AudioService.playSuccess();
      } else {
        await AudioService.playFailed();
      }

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSuccess = null;
          _resultMessage = null;
        });
      }
    } catch (e) {
      Logger.error('Capture error: $e');
      if (mounted) {
        await AudioService.playFailed();

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

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _getRotation(widget.camera.sensorOrientation),
          format: Platform.isAndroid
              ? InputImageFormat.nv21
              : InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      Logger.error('Camera image conversion error: $e');
      return null;
    }
  }

  InputImageRotation _getRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
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

          // Face overlay
          if (_shouldShowOverlay && _faceRect != null && _imageSize != null)
            CustomPaint(
              painter: FaceCircleOverlay(
                faceRect: _faceRect!,
                imageSize: _imageSize!,
                previewSize: _controller!.value.previewSize!,
                cameraLensDirection: widget.camera.lensDirection,
                isCorrect: _isFaceCorrect,
              ),
            ),

          // Result message
          if (_resultMessage != null)
            Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: (_isSuccess! ? Colors.green : Colors.red)
                      .withOpacity(0.9),
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
    Logger.info('Face Detection Screen disposed');
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }
}
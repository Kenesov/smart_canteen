import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FaceCircleOverlay extends CustomPainter {
  final Rect faceRect;
  final Size imageSize;
  final Size previewSize;
  final CameraLensDirection cameraLensDirection;
  final bool isCorrect;

  FaceCircleOverlay({
    required this.faceRect,
    required this.imageSize,
    required this.previewSize,
    required this.cameraLensDirection,
    required this.isCorrect,
  });

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    required CameraLensDirection cameraLensDirection,
  }) {
    final scaleX = widgetSize.width / imageSize.height;
    final scaleY = widgetSize.height / imageSize.width;

    double left = rect.left * scaleX;
    double top = rect.top * scaleY;
    double right = rect.right * scaleX;
    double bottom = rect.bottom * scaleY;

    if (cameraLensDirection == CameraLensDirection.front) {
      final mirrorLeft = widgetSize.width - right;
      final mirrorRight = widgetSize.width - left;
      left = mirrorLeft;
      right = mirrorRight;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = _scaleRect(
      rect: faceRect,
      imageSize: imageSize,
      widgetSize: size,
      cameraLensDirection: cameraLensDirection,
    );

    final center = rect.center;
    final radius = (rect.width > rect.height ? rect.width : rect.height) / 2;

    final paint = Paint()
      ..color = isCorrect ? Colors.green : Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(center, radius, paint);

    final innerPaint = Paint()
      ..color = (isCorrect ? Colors.green : Colors.red).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, innerPaint);
  }

  @override
  bool shouldRepaint(FaceCircleOverlay oldDelegate) {
    return oldDelegate.faceRect != faceRect || oldDelegate.isCorrect != isCorrect;
  }
}
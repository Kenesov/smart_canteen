import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

enum ScanMode { face, qr }

class ScanModeMenu extends StatelessWidget {
  final ScanMode currentMode;
  final VoidCallback onFaceTap;
  final VoidCallback onQrTap;

  const ScanModeMenu({
    Key? key,
    required this.currentMode,
    required this.onFaceTap,
    required this.onQrTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Face button
          InkWell(
            onTap: currentMode == ScanMode.face ? null : onFaceTap,
            child: Container(
              decoration: BoxDecoration(
                color: currentMode == ScanMode.face
                    ? AppConstants.primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.face,
                    color: currentMode == ScanMode.face
                        ? Colors.white
                        : Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Yuz',
                    style: TextStyle(
                      color: currentMode == ScanMode.face
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 14,
                      fontWeight: currentMode == ScanMode.face
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // QR button
          InkWell(
            onTap: currentMode == ScanMode.qr ? null : onQrTap,
            child: Container(
              decoration: BoxDecoration(
                color: currentMode == ScanMode.qr
                    ? AppConstants.primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    color: currentMode == ScanMode.qr
                        ? Colors.white
                        : Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'QR',
                    style: TextStyle(
                      color: currentMode == ScanMode.qr
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 14,
                      fontWeight: currentMode == ScanMode.qr
                          ? FontWeight.bold
                          : FontWeight.w500,
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
}
import 'package:flutter/material.dart';  
  
class QrScannerOverlayShape extends ShapeBorder {  
  final Color borderColor;  
  final double borderWidth;  
  final Color overlayColor;  
  final double borderRadius;  
  final double borderLength;  
  final double cutOutSize;  
  
  const QrScannerOverlayShape({  
    this.borderColor = Colors.white,  
    this.borderWidth = 3.0,  
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),  
    this.borderRadius = 0,  
    this.borderLength = 40,  
    this.cutOutSize = 250,  
  });  
  
  @override  
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);  
  
  @override  
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {  
    return Path()  
      ..fillType = PathFillType.evenOdd  
      ..addPath(getOuterPath(rect), Offset.zero);  
  }  
  
  @override  
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {  
    Path getLeftTopPath(Rect rect) {  
      return Path()  
        ..moveTo(rect.left, rect.bottom)  
        ..lineTo(rect.left, rect.top + borderRadius)  
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)  
        ..lineTo(rect.right, rect.top);  
    }  
  
    return getLeftTopPath(rect)  
      ..lineTo(rect.right, rect.bottom)  
      ..lineTo(rect.left, rect.bottom)  
      ..lineTo(rect.left, rect.top);  
  }  
  
  @override  
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {  
    final width = rect.width;  
    final borderWidthSize = width / 2;  
    final height = rect.height;  
    final borderOffset = borderWidth / 2;  
    final calculatedCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;  
    final effectiveBorderLength = borderLength > calculatedCutOutSize / 2 + borderWidth * 2  
        ? borderWidthSize / 2  
        : borderLength;  
  
    final backgroundPaint = Paint()  
      ..color = overlayColor  
      ..style = PaintingStyle.fill;  
  
    final borderPaint = Paint()  
      ..color = borderColor  
      ..style = PaintingStyle.stroke  
      ..strokeWidth = borderWidth;  
  
    final boxPaint = Paint()  
      ..color = borderColor  
      ..style = PaintingStyle.fill  
      ..blendMode = BlendMode.dstOut;  
  
    final cutOutRect = Rect.fromLTWH(  
      rect.left + width / 2 - calculatedCutOutSize / 2,  
      rect.top + height / 2 - calculatedCutOutSize / 2,  
      calculatedCutOutSize,  
      calculatedCutOutSize,  
    );  
  
    // Fill the background  
    canvas.drawRect(rect, backgroundPaint);  
      
    // Cut out the scanning area  
    canvas.drawRect(cutOutRect, boxPaint);  
  
    // Draw corner borders  
    final cornerPath = Path();  
      
    // Top left corner  
    cornerPath.moveTo(cutOutRect.left - borderOffset, cutOutRect.top + effectiveBorderLength);  
    cornerPath.lineTo(cutOutRect.left - borderOffset, cutOutRect.top + borderRadius);  
    cornerPath.quadraticBezierTo(  
      cutOutRect.left - borderOffset,  
      cutOutRect.top - borderOffset,  
      cutOutRect.left + borderRadius,  
      cutOutRect.top - borderOffset,  
    );  
    cornerPath.lineTo(cutOutRect.left + effectiveBorderLength, cutOutRect.top - borderOffset);  
  
    // Top right corner  
    cornerPath.moveTo(cutOutRect.right - effectiveBorderLength, cutOutRect.top - borderOffset);  
    cornerPath.lineTo(cutOutRect.right - borderRadius, cutOutRect.top - borderOffset);  
    cornerPath.quadraticBezierTo(  
      cutOutRect.right + borderOffset,  
      cutOutRect.top - borderOffset,  
      cutOutRect.right + borderOffset,  
      cutOutRect.top + borderRadius,  
    );  
    cornerPath.lineTo(cutOutRect.right + borderOffset, cutOutRect.top + effectiveBorderLength);  
  
    // Bottom right corner  
    cornerPath.moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom - effectiveBorderLength);  
    cornerPath.lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderRadius);  
    cornerPath.quadraticBezierTo(  
      cutOutRect.right + borderOffset,  
      cutOutRect.bottom + borderOffset,  
      cutOutRect.right - borderRadius,  
      cutOutRect.bottom + borderOffset,  
    );  
    cornerPath.lineTo(cutOutRect.right - effectiveBorderLength, cutOutRect.bottom + borderOffset);  
  
    // Bottom left corner  
    cornerPath.moveTo(cutOutRect.left + effectiveBorderLength, cutOutRect.bottom + borderOffset);  
    cornerPath.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom + borderOffset);  
    cornerPath.quadraticBezierTo(  
      cutOutRect.left - borderOffset,  
      cutOutRect.bottom + borderOffset,  
      cutOutRect.left - borderOffset,  
      cutOutRect.bottom - borderRadius,  
    );  
    cornerPath.lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom - effectiveBorderLength);  
  
    canvas.drawPath(cornerPath, borderPaint);  
  }  
  
  @override  
  ShapeBorder scale(double t) => QrScannerOverlayShape(  
        borderColor: borderColor,  
        borderWidth: borderWidth * t,  
        overlayColor: overlayColor,  
        borderRadius: borderRadius * t,  
        borderLength: borderLength * t,  
        cutOutSize: cutOutSize * t,  
      );  
}
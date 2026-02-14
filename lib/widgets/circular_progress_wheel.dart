import 'dart:math';
import 'package:flutter/material.dart';

class CircularProgressWheel extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final ValueChanged<double>? onProgressChanged;
  final double size;
  final Color color;
  final bool interactive;

  const CircularProgressWheel({
    super.key,
    required this.progress,
    this.onProgressChanged,
    this.size = 60,
    this.color = const Color(0xFF5FCBAA),
    this.interactive = true,
  });

  @override
  State<CircularProgressWheel> createState() => _CircularProgressWheelState();
}

class _CircularProgressWheelState extends State<CircularProgressWheel> {
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.progress;
  }

  @override
  void didUpdateWidget(CircularProgressWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _currentProgress = widget.progress;
    }
  }

  void _updateProgress(Offset localPosition) {
    if (!widget.interactive) return;

    final center = Offset(widget.size / 2, widget.size / 2);
    final angle = atan2(
      localPosition.dy - center.dy,
      localPosition.dx - center.dx,
    );
    
    // Convert angle to progress (0 to 1)
    // Start from top (270 degrees) and go clockwise
    double progress = (angle + pi / 2) / (2 * pi);
    if (progress < 0) progress += 1;
    
    setState(() {
      _currentProgress = progress.clamp(0.0, 1.0);
    });
    
    widget.onProgressChanged?.call(_currentProgress);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: widget.interactive
          ? (details) => _updateProgress(details.localPosition)
          : null,
      onTapDown: widget.interactive
          ? (details) => _updateProgress(details.localPosition)
          : null,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _CircularProgressPainter(
            progress: _currentProgress,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.15;

    // Background circle (light)
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Draggable handle
    if (progress > 0) {
      final handleAngle = -pi / 2 + sweepAngle;
      final handleX = center.dx + (radius - strokeWidth / 2) * cos(handleAngle);
      final handleY = center.dy + (radius - strokeWidth / 2) * sin(handleAngle);
      
      final handlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      final handleBorderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(Offset(handleX, handleY), strokeWidth * 0.6, handlePaint);
      canvas.drawCircle(Offset(handleX, handleY), strokeWidth * 0.6, handleBorderPaint);
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

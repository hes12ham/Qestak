import 'package:flutter/material.dart';
import 'dart:math';
import '../config/theme.dart';

class PaymentProgressRing extends StatelessWidget {
  final double progress;
  final double paidAmount;
  final double totalAmount;
  final String currency;
  final String label;

  const PaymentProgressRing({
    super.key,
    required this.progress,
    required this.paidAmount,
    required this.totalAmount,
    required this.currency,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        SizedBox(
          width: 140, height: 140,
          child: CustomPaint(
            painter: _RingPainter(progress: progress),
            child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$pct%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _color)),
                Text('${_fmt(paidAmount)} / ${_fmt(totalAmount)}',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            )),
          ),
        ),
        if (label.isNotEmpty) ...[const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary))],
      ]),
    );
  }

  Color get _color => progress >= 1 ? AppColors.success : progress >= 0.5 ? AppColors.primary : progress >= 0.25 ? AppColors.warning : AppColors.danger;
  String _fmt(double n) => n >= 1000 ? '${(n/1000).toStringAsFixed(n%1000==0?0:1)}K' : n.toStringAsFixed(n==n.roundToDouble()?0:2);
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width/2, size.height/2);
    final r = size.width/2 - 8;
    canvas.drawCircle(c, r, Paint()..color=AppColors.divider..style=PaintingStyle.stroke..strokeWidth=10..strokeCap=StrokeCap.round);
    if (progress > 0) {
      final color = progress >= 1 ? AppColors.success : progress >= 0.5 ? AppColors.primary : progress >= 0.25 ? AppColors.warning : AppColors.danger;
      canvas.drawArc(Rect.fromCircle(center:c,radius:r), -pi/2, 2*pi*progress.clamp(0.0,1.0), false,
          Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=10..strokeCap=StrokeCap.round);
    }
  }
  @override
  bool shouldRepaint(covariant _RingPainter o) => o.progress != progress;
}

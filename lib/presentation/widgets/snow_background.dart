import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Yavaş, sürekli kar — dikkat dağıtmayacak hızda (tam döngü ~75 sn).
class SnowBackground extends StatefulWidget {
  const SnowBackground({super.key});

  @override
  State<SnowBackground> createState() => _SnowBackgroundState();
}

class _SnowBackgroundState extends State<SnowBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<_Flake> _flakes;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(42);
    _flakes = List.generate(38, (_) => _Flake.random(rnd));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 95),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SnowPainter(
              progress: _controller.value,
              flakes: _flakes,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _Flake {
  _Flake({
    required this.x,
    required this.yPhase,
    required this.speed,
    required this.r,
    required this.opacity,
    required this.wobbleAmp,
    required this.wobblePhase,
  });

  final double x;
  final double yPhase;
  final double speed;
  final double r;
  final double opacity;
  final double wobbleAmp;
  final double wobblePhase;

  factory _Flake.random(math.Random rnd) {
    return _Flake(
      x: rnd.nextDouble(),
      yPhase: rnd.nextDouble(),
      speed: 0.28 + rnd.nextDouble() * 0.55,
      r: 0.7 + rnd.nextDouble() * 2.0,
      opacity: 0.08 + rnd.nextDouble() * 0.28,
      wobbleAmp: 3 + rnd.nextDouble() * 9,
      wobblePhase: rnd.nextDouble() * math.pi * 2,
    );
  }
}

class _SnowPainter extends CustomPainter {
  _SnowPainter({required this.progress, required this.flakes});

  final double progress;
  final List<_Flake> flakes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flakes) {
      final yNorm = (f.yPhase + progress * f.speed * 0.92) % 1.0;
      final y = yNorm * (size.height + 40) - 20;
      final wobble =
          math.sin(progress * math.pi * 2 * 0.75 + f.wobblePhase) * f.wobbleAmp;
      final x = f.x * size.width + wobble;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: f.opacity)
        ..isAntiAlias = true;
      canvas.drawCircle(Offset(x, y), f.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

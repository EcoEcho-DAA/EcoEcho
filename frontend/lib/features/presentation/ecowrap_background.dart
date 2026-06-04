import 'dart:math' as math;
import 'package:flutter/material.dart';

enum EcoWrapPage { milestone, postLogs, tierUnlock, treePlanting, summary }

class EcoWrapBackground extends StatefulWidget {
  final EcoWrapPage page;
  final Widget child;

  const EcoWrapBackground({
    super.key,
    required this.page,
    required this.child,
  });

  @override
  State<EcoWrapBackground> createState() => _EcoWrapBackgroundState();
}

class _EcoWrapBackgroundState extends State<EcoWrapBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _pageConfigs = { //placeholder colors, replace color  later
    EcoWrapPage.milestone: _BackgroundConfig(
      baseColor: Color(0xFFE8F5E1),
      circleColors: [Color(0xFF386A2B), Color(0xFF5A9E42), Color(0xFFA8D5A2)],
    ),
    EcoWrapPage.postLogs: _BackgroundConfig(
      baseColor: Color(0xFFF5EDE8),
      circleColors: [Color(0xFF885124), Color(0xFFB87A50), Color(0xFFDDB899)],
    ),
    EcoWrapPage.tierUnlock: _BackgroundConfig(
      baseColor: Color(0xFFFFF8E1),
      circleColors: [Color(0xFFFFB300), Color(0xFFFFD54F), Color(0xFFFFF176)],
    ),
    EcoWrapPage.treePlanting: _BackgroundConfig(
      baseColor: Color(0xFFE1F0E8),
      circleColors: [Color(0xFF2E7D52), Color(0xFF4CAF7D), Color(0xFF9ED4B5)],
    ),
    EcoWrapPage.summary: _BackgroundConfig(
      baseColor: Color(0xFFEAF4FB),
      circleColors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF90CAF9)],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _pageConfigs[widget.page]!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _RadialBackgroundPainter(
          config: config,
          animValue: _controller.value,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _BackgroundConfig {
  final Color baseColor;
  final List<Color> circleColors;
  const _BackgroundConfig({required this.baseColor, required this.circleColors});
}

class _RadialBackgroundPainter extends CustomPainter {
  final _BackgroundConfig config;
  final double animValue;

  const _RadialBackgroundPainter({
    required this.config,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // base fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = config.baseColor,
    );

    // 3 overlapping radial gradient circles (echo-waves)
    final circles = [
      _CircleConfig(
        center: Offset(
          size.width * (0.2 + 0.1 * math.sin(animValue * math.pi)),
          size.height * (0.2 + 0.05 * math.cos(animValue * math.pi)),
        ),
        radius: size.width * (0.55 + 0.05 * math.sin(animValue * math.pi)),
        color: config.circleColors[0],
        opacity: 0.18,
      ),
      _CircleConfig(
        center: Offset(
          size.width * (0.8 - 0.08 * math.cos(animValue * math.pi)),
          size.height * (0.35 + 0.08 * math.sin(animValue * math.pi)),
        ),
        radius: size.width * (0.5 + 0.04 * math.cos(animValue * math.pi)),
        color: config.circleColors[1],
        opacity: 0.14,
      ),
      _CircleConfig(
        center: Offset(
          size.width * (0.5 + 0.06 * math.sin(animValue * math.pi * 1.3)),
          size.height * (0.75 + 0.06 * math.cos(animValue * math.pi * 1.3)),
        ),
        radius: size.width * (0.6 + 0.06 * math.sin(animValue * math.pi * 0.7)),
        color: config.circleColors[2],
        opacity: 0.12,
      ),
    ];

    for (final c in circles) {
      canvas.drawCircle(
        c.center,
        c.radius,
        Paint()
          ..shader = RadialGradient(
            colors: [c.color.withValues(alpha: c.opacity), Colors.transparent],
            stops: const [0.0, 1.0],
          ).createShader(Rect.fromCircle(center: c.center, radius: c.radius)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialBackgroundPainter old) =>
      old.animValue != animValue || old.config != config;
}

class _CircleConfig {
  final Offset center;
  final double radius;
  final Color color;
  final double opacity;
  const _CircleConfig({
    required this.center,
    required this.radius,
    required this.color,
    required this.opacity,
  });
}
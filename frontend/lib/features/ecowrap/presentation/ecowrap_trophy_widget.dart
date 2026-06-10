import 'package:flutter/material.dart';

class EcoWrapTrophyWidget extends StatefulWidget {
  final double percentile; 
  final String assetPath;  

  // TODO: The asset defaults to this standard trophy if custom icon yet to be provided
  const EcoWrapTrophyWidget({
    super.key,
    required this.percentile,
    this.assetPath = 'assets/images/trophy.png',
  });

  @override
  State<EcoWrapTrophyWidget> createState() => _EcoWrapTrophyWidgetState();
}

class _EcoWrapTrophyWidgetState extends State<EcoWrapTrophyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // slight overshoot for a natural pop feel
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    // small delay so the page is settled before trophy pops
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // glow ring behind trophy
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF386A2B).withValues(alpha:0.15),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF386A2B).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // TODO: trophy image to be replace with custom trophy asset once available
                Image.asset(
                  widget.assetPath,
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 80,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'home.dart'; // Your HomeScreen import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Background wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Fade-in animation for logo/text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Pulse effect for logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 1.0,
      upperBound: 1.1,
    )..repeat(reverse: true);

    // Navigate to HomeScreen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Scaffold(
          body: CustomPaint(
            painter: FloatingBlanketPainter(_waveController.value),
            child: Center(
              child: FadeTransition(
                opacity: _fadeController,
                child: ScaleTransition(
                  scale: _pulseController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/NammaRaithaLOGO.png',
                        width: 220,
                        height: 220,
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Namma Raitha',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Empowering Farmers & Retailers',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for the dancing blanket background
class FloatingBlanketPainter extends CustomPainter {
  final double animationValue;
  FloatingBlanketPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Gradient background that blends two shades of green
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF417d43).withOpacity(0.9),
        const Color(0xFFa5d147).withOpacity(0.9),
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);

    // Base background
    canvas.drawRect(rect, paint);

    // Add floating wave overlay (dancing effect)
    final path = Path();
    final waveHeight = 30.0;
    final waveSpeed = animationValue * 2 * pi;

    path.moveTo(0, size.height * 0.5);
    for (double i = 0; i <= size.width; i++) {
      final y = sin((i / size.width * 2 * pi) + waveSpeed) * waveHeight +
          size.height * 0.5;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant FloatingBlanketPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

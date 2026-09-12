import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget? nextScreen;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2200),
    this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  Timer? _timer;

  double _progress = 0.0;
  String _statusMessage = 'Initializing secure vault...';

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (scale, fade, slide)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Continuous breathing & levitation pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _entranceController.forward();
    _pulseController.repeat();

    // 3. Dynamic progress simulation & status updates
    _startProgress();
  }

  void _startProgress() {
    const totalSteps = 25;
    final stepDuration = widget.duration.inMilliseconds / totalSteps;
    int currentStep = 0;

    Timer.periodic(Duration(milliseconds: stepDuration.round()), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep++;
      final newProgress = math.min(1.0, currentStep / totalSteps);

      setState(() {
        _progress = newProgress;
        if (_progress < 0.30) {
          _statusMessage = 'Initializing secure vault...';
        } else if (_progress < 0.60) {
          _statusMessage = 'Loading accounts & budgets...';
        } else if (_progress < 0.88) {
          _statusMessage = 'Syncing market rates & debt engine...';
        } else {
          _statusMessage = 'Ready';
        }
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
        _pulseController.stop();
        _navigateToNext();
      }
    });
  }

  void _navigateToNext() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) =>
            widget.nextScreen ?? const HomeScreen(),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF064E3B);
    const deepNavy = Color(0xFF0B132B);
    const emerald = Color(0xFF047857);
    const mintAccent = Color(0xFF10B981);
    const brightMint = Color(0xFF34D399);

    return Scaffold(
      body: Stack(
        children: [
          // A. Dynamic Atmospheric Gradient
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = math.sin(_pulseController.value * 2 * math.pi);
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.15 + (pulse * 0.05)),
                    radius: 1.1 + (pulse * 0.08),
                    colors: const [
                      emerald,
                      darkGreen,
                      deepNavy,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              );
            },
          ),

          // C. Center Content (Logo, Glow, Title, Status & Progress)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // 1. 3D Logo with Floating Levitation
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final levitation = math.sin(_pulseController.value * 2 * math.pi) * 5;
                    final haloPulse = math.sin(_pulseController.value * 2 * math.pi) * 0.5 + 0.5;

                    return Transform.translate(
                      offset: Offset(0, levitation),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glowing Ambient Radial Halo
                            Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    mintAccent.withValues(alpha: 0.35 + (haloPulse * 0.2)),
                                    brightMint.withValues(alpha: 0.15),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.2, 0.65, 1.0],
                                ),
                              ),
                            ),

                            // Master 3D Squircle Logo
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                  BoxShadow(
                                    color: mintAccent.withValues(alpha: 0.35),
                                    blurRadius: 36,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, _, __) => Container(
                                    color: mintAccent,
                                    child: const Icon(Icons.account_balance_wallet,
                                        size: 64, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // 2. Brand Name & Pill Badge
                AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      const Text(
                        'FirmLedger',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: mintAccent.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Small Business Accounting & Debt Engine',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // 3. Dynamic Progress Bar, Percentage & Loading Status
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        // Dynamic Status Text with Smooth Transition
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.25),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _statusMessage,
                            key: ValueKey(_statusMessage),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sleek Gradient Progress Bar
                        Stack(
                          children: [
                            // Progress Background Track
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            // Active Progress Fill
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  height: 6,
                                  width: constraints.maxWidth * _progress,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [mintAccent, brightMint, Colors.white],
                                      stops: [0.0, 0.85, 1.0],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: mintAccent.withValues(alpha: 0.6),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Numeric Percentage & Version
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'v1.0.0 • Offline-First',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white38,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              '${(_progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: brightMint,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late AnimationController _glowController;

  final List<String> _messages = [
    'Consultando a la IA',
    'Generando palabra secreta',
    'Preparando la partida',
    'Casi listo',
  ];
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return false;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
      return true;
    });
  }

  @override
  void dispose() {
    _dotController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.lightBg1, AppColors.lightBg2, AppColors.lightBg3],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated glow circle with icon
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final glow = Curves.easeInOut
                      .transform(_glowController.value);
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blue.withValues(alpha: 0.06 + glow * 0.06),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.08 + glow * 0.12),
                          blurRadius: 40 + glow * 20,
                          spreadRadius: glow * 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cardWhite,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withValues(alpha: 0.15),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 32,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Message with animated dots
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Row(
                  key: ValueKey(_messageIndex),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _messages[_messageIndex],
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(width: 2),
                    _AnimatedDots(controller: _dotController),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Progress bar
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.blue.withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.blue),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.25;
            final opacity =
                ((value - delay) % 1.0).clamp(0.0, 0.5) * 2;
            return Opacity(
              opacity: opacity,
              child: Text(
                '.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

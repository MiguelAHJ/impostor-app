import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class OnlineSuspenseScreen extends StatefulWidget {
  const OnlineSuspenseScreen({super.key});

  @override
  State<OnlineSuspenseScreen> createState() => _OnlineSuspenseScreenState();
}

class _OnlineSuspenseScreenState extends State<OnlineSuspenseScreen>
    with TickerProviderStateMixin {
  // Phase 0: "Calculando..." (3s), Phase 1: result revealed (3s), then transition
  int _phase = 0;
  int _secondsLeft = 3;
  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    );

    _startPhase(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _startPhase(int phase) {
    _timer?.cancel();
    setState(() {
      _phase = phase;
      _secondsLeft = 3;
    });

    if (phase == 1) {
      _revealController.forward(from: 0);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        t.cancel();
        if (phase == 0) {
          _startPhase(1);
        } else {
          // Done — let GameProvider decide what's next
          context.read<GameProvider>().resolveOnlineSuspense();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final eliminated = game.votingClosedEliminated;
    final reason = game.votingClosedReason;

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
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 16),

          // Header
          Text(
            'Votación',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          Text(
            'RESULTADO',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.blue,
              letterSpacing: 1,
            ),
          ),

          const Spacer(),

          if (_phase == 0)
            _buildCalculating()
          else
            _buildResult(eliminated, reason),

          const Spacer(),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildCalculating() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          ),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(
              Icons.how_to_vote_rounded,
              size: 48,
              color: AppColors.blue,
            ),
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Calculando resultado...',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Los votos han sido contados',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),

        const SizedBox(height: 40),

        // Countdown dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final active = i < _secondsLeft;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: active ? 14 : 10,
              height: active ? 14 : 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.blue
                    : Colors.grey.shade300,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildResult(String? eliminated, String reason) {
    final isElimination = eliminated != null;
    final isTie = reason == 'tie';

    Color mainColor;
    IconData mainIcon;
    String headline;
    String subtext;

    if (isElimination) {
      mainColor = const Color(0xFFE53935);
      mainIcon = Icons.person_remove_rounded;
      headline = eliminated;
      subtext = 'ha sido eliminado';
    } else if (isTie) {
      mainColor = const Color(0xFFFF8F00);
      mainIcon = Icons.balance_rounded;
      headline = '¡Empate!';
      subtext = 'Nadie fue eliminado esta ronda';
    } else {
      // no_votes
      mainColor = Colors.grey.shade600;
      mainIcon = Icons.how_to_vote_outlined;
      headline = 'Sin votos';
      subtext = 'Nadie votó esta ronda';
    }

    return ScaleTransition(
      scale: _revealAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: mainColor.withValues(alpha: 0.12),
              border: Border.all(color: mainColor.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(mainIcon, size: 50, color: mainColor),
          ),

          const SizedBox(height: 28),

          Text(
            headline,
            style: GoogleFonts.outfit(
              fontSize: isElimination ? 32 : 28,
              fontWeight: FontWeight.w900,
              color: mainColor,
              letterSpacing: isElimination ? 0 : 1,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            subtext,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),

          if (!isElimination) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Nueva ronda de discusión',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mainColor,
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Countdown dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i < _secondsLeft;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: active ? 14 : 10,
                height: active ? 14 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? mainColor : Colors.grey.shade300,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

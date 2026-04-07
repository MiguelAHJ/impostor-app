import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class OnlineDiscussionScreen extends StatefulWidget {
  const OnlineDiscussionScreen({super.key});

  @override
  State<OnlineDiscussionScreen> createState() => _OnlineDiscussionScreenState();
}

class _OnlineDiscussionScreenState extends State<OnlineDiscussionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  double _progress = 1.0;
  bool _timerExpired = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _ticker.addListener(_onTick);
  }

  void _onTick() {
    if (_timerExpired || !mounted) return;
    final game = context.read<GameProvider>();
    final deadlineMs = game.onlineDiscussionDeadlineMs;
    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = deadlineMs - now;

    if (remainingMs <= 0) {
      setState(() {
        _progress = 0;
        _timerExpired = true;
      });
      game.closeOnlineVoting();
    } else {
      setState(() {
        _progress = remainingMs / 300000;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final speakingOrder = game.onlineSpeakingOrder;
    final voteCount = game.onlineVoteCount;
    final voteTotal = game.onlineVoteTotal;
    final myVote = game.myOnlineVote;
    final localName = game.localPlayerName;

    final deadlineMs = game.onlineDiscussionDeadlineMs;
    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = (deadlineMs - now).clamp(0, 300000);
    final remaining = remainingMs / 1000.0;
    final minutes = (remaining ~/ 60);
    final seconds = (remaining % 60).toInt();
    final isLow = remaining < 60;

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
          // App Bar
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Ronda ${game.roundNumber}',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        'DISCUSIÓN ONLINE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          // Timer
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _TimerPainter(progress: _progress, isLow: isLow),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: isLow ? const Color(0xFFE53935) : AppColors.darkText,
                      ),
                    ),
                    Text(
                      'RESTANTE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Vote count banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.how_to_vote_outlined,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  '$voteCount / $voteTotal han votado',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Speaking order header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Orden de habla',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Player list with vote buttons
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: speakingOrder.length,
              itemBuilder: (ctx, i) {
                final name = speakingOrder[i];
                final isMe = name == localName;
                final iVotedForThis = myVote == name;
                final color = AppColors.avatarColors[i % AppColors.avatarColors.length];
                final canVote = !_timerExpired && !isMe && myVote == null;
                final canRetract = !_timerExpired && iVotedForThis &&
                    voteCount < voteTotal;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: iVotedForThis
                        ? const Color(0xFFE53935).withValues(alpha: 0.08)
                        : AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: iVotedForThis
                        ? Border.all(
                            color: const Color(0xFFE53935).withValues(alpha: 0.3))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Order number
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Icon(Icons.person, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Name
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkText,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'tú',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Vote button
                      if (!isMe)
                        GestureDetector(
                          onTap: () {
                            if (canRetract) {
                              context.read<GameProvider>().retractOnlineVote();
                            } else if (canVote) {
                              context.read<GameProvider>().castOnlineVote(name);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: iVotedForThis
                                  ? const Color(0xFFE53935)
                                  : (canVote
                                      ? const Color(0xFFE53935).withValues(alpha: 0.1)
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              iVotedForThis
                                  ? Icons.how_to_vote_rounded
                                  : Icons.how_to_vote_outlined,
                              size: 18,
                              color: iVotedForThis
                                  ? Colors.white
                                  : (canVote
                                      ? const Color(0xFFE53935)
                                      : Colors.grey.shade400),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final bool isLow;

  _TimerPainter({required this.progress, required this.isLow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..color = const Color(0xFFE8E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    final color = isLow ? const Color(0xFFE53935) : AppColors.blue;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter old) =>
      old.progress != progress || old.isLow != isLow;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.lightBg1,
            AppColors.lightBg2,
            AppColors.lightBg3,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Logo / Title
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  size: 44,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Impostor',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige un modo de juego',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtitleText,
                ),
              ),
              const SizedBox(height: 40),

              // Local mode card
              _ModeCard(
                icon: Icons.people_rounded,
                iconColor: AppColors.blue,
                title: 'Local',
                subtitle: 'Un solo dispositivo que se pasa de mano en mano',
                onTap: () {
                  context.read<GameProvider>().selectMode(GameMode.local);
                },
              ),
              const SizedBox(height: 16),

              // Online header
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_rounded, size: 16, color: AppColors.subtitleText),
                      const SizedBox(width: 6),
                      Text(
                        'Online',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.subtitleText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Online voice card
              _ModeCard(
                icon: Icons.mic_rounded,
                iconColor: AppColors.primary,
                title: 'Por voz',
                subtitle: 'Cada jugador usa su dispositivo. Hablan por Discord u otra app',
                onTap: () {
                  context.read<GameProvider>().selectMode(GameMode.onlineVoice);
                },
              ),
              const SizedBox(height: 12),

              // Online chat card (coming soon)
              _ModeCard(
                icon: Icons.chat_rounded,
                iconColor: AppColors.subtitleText,
                title: 'Por chat',
                subtitle: 'Chat integrado en la app',
                enabled: false,
                badge: 'En desarrollo',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final String? badge;

  const _ModeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.5;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.subtitleText.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.subtitleText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: AppColors.subtitleText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.subtitleText,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

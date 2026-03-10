import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/role_reveal_screen.dart';
import 'screens/playing_screen.dart';
import 'screens/voting_screen.dart';
import 'screens/elimination_reveal_screen.dart';
import 'screens/result_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Impostor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const GameShell(),
    );
  }
}

class GameShell extends StatelessWidget {
  const GameShell({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.select<GameProvider, GamePhase>((g) => g.phase);
    final error = context.select<GameProvider, String?>((g) => g.loadingError);

    // Show error snackbar when returning to setup after a failed load
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.impostor,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    Widget body;
    switch (phase) {
      case GamePhase.setup:
        body = const SetupScreen();
      case GamePhase.loading:
        body = const LoadingScreen();
      case GamePhase.reveal:
        body = const RoleRevealScreen();
      case GamePhase.playing:
        body = const PlayingScreen();
      case GamePhase.voting:
        body = const VotingScreen();
      case GamePhase.elimination:
        body = const EliminationRevealScreen();
      case GamePhase.result:
        body = const ResultScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey(phase),
            child: body,
          ),
        ),
      ),
    );
  }
}

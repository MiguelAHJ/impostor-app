import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../models/word_entry.dart';
import '../services/api_service.dart';

enum GamePhase { setup, loading, reveal, playing, voting, elimination, result }

class GameProvider extends ChangeNotifier {
  GamePhase _phase = GamePhase.setup;
  List<Player> _players = [];
  int _impostorCount = 1;
  WordEntry? _currentWord;
  String _impostorClue = '';
  int _currentRevealIndex = 0;
  int _firstSpeakerIndex = 0;
  int _roundNumber = 1;
  bool _showRoleOnElimination = false;
  bool _impostorHasClue = true;
  int _lastEliminatedIndex = -1;
  String? _loadingError;

  static const _lastNamesKey = 'party-game-last-names';
  static const _lastImpostorsKey = 'party-game-last-impostors';
  static const _lastShowRoleKey = 'party-game-last-show-role';
  static const _lastImpostorHasClueKey = 'party-game-last-impostor-has-clue';
  final _random = Random();

  static Future<
      ({
        List<String> names,
        int impostors,
        bool showRole,
        bool impostorHasClue
      })?> loadLastSession() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_lastNamesKey);
    final impostors = prefs.getInt(_lastImpostorsKey);
    final showRole = prefs.getBool(_lastShowRoleKey);
    final impostorHasClue = prefs.getBool(_lastImpostorHasClueKey);
    if (names == null || names.isEmpty) return null;
    return (
      names: names,
      impostors: impostors ?? 1,
      showRole: showRole ?? false,
      impostorHasClue: impostorHasClue ?? true,
    );
  }

  // Getters
  GamePhase get phase => _phase;
  List<Player> get players => _players;
  int get impostorCount => _impostorCount;
  WordEntry? get currentWord => _currentWord;
  String get impostorClue => _impostorClue;
  int get currentRevealIndex => _currentRevealIndex;
  int get firstSpeakerIndex => _firstSpeakerIndex;
  int get roundNumber => _roundNumber;
  bool get showRoleOnElimination => _showRoleOnElimination;
  bool get impostorHasClue => _impostorHasClue;
  int get lastEliminatedIndex => _lastEliminatedIndex;
  String? get loadingError => _loadingError;
  List<Player> get alivePlayers => _players.where((p) => p.alive).toList();

  Future<({WordEntry word, String clue})> _pickWord() async {
    final word = await ApiService().fetchRandomWord();
    final clue = word.pistaImpostor[_random.nextInt(word.pistaImpostor.length)];
    return (word: word, clue: clue);
  }

  Future<void> startGame(List<String> names, int impostors,
      {bool showRoleOnElimination = false, bool impostorHasClue = true}) async {
    // Persist session for next game
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lastNamesKey, names);
    await prefs.setInt(_lastImpostorsKey, impostors);
    await prefs.setBool(_lastShowRoleKey, showRoleOnElimination);
    await prefs.setBool(_lastImpostorHasClueKey, impostorHasClue);

    _showRoleOnElimination = showRoleOnElimination;
    _impostorHasClue = impostorHasClue;
    _loadingError = null;

    // Mostrar pantalla de carga mientras la IA genera la palabra
    _phase = GamePhase.loading;
    notifyListeners();

    final ({WordEntry word, String clue}) result;
    try {
      result = await _pickWord();
    } catch (e) {
      _loadingError =
          'No se pudo conectar al servidor.\nVerifica la IP en api_service.dart y que el backend esté corriendo.';
      _phase = GamePhase.setup;
      notifyListeners();
      return;
    }

    // Asignar roles aleatoriamente pero conservar el orden de registro.
    // Se elige al azar qué posiciones serán impostores, sin reordenar la lista.
    final indices = List.generate(names.length, (i) => i)..shuffle(_random);
    final impostorIndices = indices.take(impostors).toSet();

    final players = names.asMap().entries.map((entry) {
      return Player(
        name: entry.value,
        role: impostorIndices.contains(entry.key) ? Role.impostor : Role.civil,
      );
    }).toList();

    final firstSpeaker = _random.nextInt(players.length);

    _phase = GamePhase.reveal;
    _players = players;
    _impostorCount = impostors;
    _currentWord = result.word;
    _impostorClue = result.clue;
    _currentRevealIndex = 0;
    _firstSpeakerIndex = firstSpeaker;
    _roundNumber = 1;
    notifyListeners();
  }

  void nextReveal() {
    _currentRevealIndex++;
    notifyListeners();
  }

  void startPlaying() {
    _phase = GamePhase.playing;
    notifyListeners();
  }

  void startVoting() {
    _phase = GamePhase.voting;
    notifyListeners();
  }

  void eliminatePlayer(int index) {
    _players = _players.asMap().entries.map((entry) {
      if (entry.key == index) {
        return entry.value.copyWith(alive: false);
      }
      return entry.value;
    }).toList();
    _lastEliminatedIndex = index;

    if (_showRoleOnElimination) {
      // Pause to show elimination reveal screen before resolving win condition
      _phase = GamePhase.elimination;
      notifyListeners();
      return;
    }

    _resolveAfterElimination();
  }

  /// Called by EliminationRevealScreen after the countdown finishes.
  void confirmElimination() {
    _resolveAfterElimination();
  }

  void _resolveAfterElimination() {
    final aliveImpostors =
        _players.where((p) => p.alive && p.role == Role.impostor).length;
    final aliveCivils =
        _players.where((p) => p.alive && p.role == Role.civil).length;

    if (aliveImpostors == 0 || aliveImpostors >= aliveCivils) {
      _phase = GamePhase.result;
    } else {
      _phase = GamePhase.playing;
      _roundNumber++;
    }
    notifyListeners();
  }

  void resetGame() {
    _phase = GamePhase.setup;
    _players = [];
    _impostorCount = 1;
    _currentWord = null;
    _impostorClue = '';
    _currentRevealIndex = 0;
    _firstSpeakerIndex = 0;
    _roundNumber = 1;
    _showRoleOnElimination = false;
    _impostorHasClue = true;
    _lastEliminatedIndex = -1;
    _loadingError = null;
    notifyListeners();
  }
}

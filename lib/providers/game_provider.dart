import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../models/word_entry.dart';
import '../data/words.dart';

enum GamePhase { setup, reveal, playing, voting, elimination, result }

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

  static const _usedIdsKey = 'party-game-used-ids';
  static const _lastNamesKey = 'party-game-last-names';
  static const _lastImpostorsKey = 'party-game-last-impostors';
  static const _lastShowRoleKey = 'party-game-last-show-role';
  static const _lastImpostorHasClueKey = 'party-game-last-impostor-has-clue';
  final _random = Random();

  static Future<({List<String> names, int impostors, bool showRole, bool impostorHasClue})?>
      loadLastSession() async {
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
  List<Player> get alivePlayers => _players.where((p) => p.alive).toList();

  Future<List<int>> _getUsedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_usedIdsKey);
    if (raw == null) return [];
    return raw.map((e) => int.tryParse(e) ?? 0).toList();
  }

  Future<void> _saveUsedIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _usedIdsKey, ids.map((e) => e.toString()).toList());
  }

  Future<({WordEntry word, String clue})> _pickWord() async {
    var usedIds = await _getUsedIds();
    var available = wordsData.where((w) => !usedIds.contains(w.id)).toList();

    if (available.isEmpty) {
      usedIds = [];
      await _saveUsedIds([]);
      available = List.from(wordsData);
    }

    final word = available[_random.nextInt(available.length)];
    final clue = word.pistaImpostor[_random.nextInt(word.pistaImpostor.length)];

    usedIds.add(word.id);
    await _saveUsedIds(usedIds);

    return (word: word, clue: clue);
  }

  List<T> _shuffle<T>(List<T> list) {
    final a = List<T>.from(list);
    for (var i = a.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = a[i];
      a[i] = a[j];
      a[j] = temp;
    }
    return a;
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

    final result = await _pickWord();
    final shuffledNames = _shuffle(names);

    var players = shuffledNames.asMap().entries.map((entry) {
      return Player(
        name: entry.value,
        role: entry.key < impostors ? Role.impostor : Role.civil,
      );
    }).toList();

    players = _shuffle(players);
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
    notifyListeners();
  }
}

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../models/word_entry.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

enum GamePhase {
  modeSelection,
  onlineName,
  onlineLobby,
  setup,
  loading,
  reveal,
  onlineReveal,
  onlineDiscussion,
  onlineSuspense,
  onlineElimination,
  playing,
  voting,
  elimination,
  result,
}

enum GameMode { local, onlineVoice, onlineChat }

class GameProvider extends ChangeNotifier {
  GamePhase _phase = GamePhase.modeSelection;
  GameMode _gameMode = GameMode.local;

  // ── Online state ──────────────────────────────────────────────────────────
  String _localPlayerName = '';
  String _roomCode = '';
  bool _isHost = false;
  List<LobbyPlayer> _lobbyPlayers = [];
  int? _countdown;
  String? _roomError;

  // Online discussion/voting state
  List<String> _onlineSpeakingOrder = [];
  int _onlineDiscussionDeadlineMs = 0;
  int _onlineVoteCount = 0;
  int _onlineVoteTotal = 0;
  String? _myOnlineVote;
  String? _votingClosedEliminated;
  String _votingClosedReason = '';
  Map<String, int> _votingTally = {};

  // ── Game state ────────────────────────────────────────────────────────────
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
  bool _timerExpired = false;
  int _elapsedSeconds = 0;
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
  GameMode get gameMode => _gameMode;
  String get localPlayerName => _localPlayerName;
  String get roomCode => _roomCode;
  bool get isHost => _isHost;
  List<LobbyPlayer> get lobbyPlayers => _lobbyPlayers;
  int? get countdown => _countdown;
  String? get roomError => _roomError;
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
  bool get timerExpired => _timerExpired;
  int get elapsedSeconds => _elapsedSeconds;
  String? get loadingError => _loadingError;
  List<Player> get alivePlayers => _players.where((p) => p.alive).toList();

  // Online discussion/voting getters
  List<String> get onlineSpeakingOrder => _onlineSpeakingOrder;
  int get onlineDiscussionDeadlineMs => _onlineDiscussionDeadlineMs;
  int get onlineVoteCount => _onlineVoteCount;
  int get onlineVoteTotal => _onlineVoteTotal;
  String? get myOnlineVote => _myOnlineVote;
  String? get votingClosedEliminated => _votingClosedEliminated;
  String get votingClosedReason => _votingClosedReason;
  Map<String, int> get votingTally => _votingTally;

  void selectMode(GameMode mode) {
    _gameMode = mode;
    _phase = mode == GameMode.local ? GamePhase.setup : GamePhase.onlineName;
    notifyListeners();
  }

  void backToModeSelection() {
    _phase = GamePhase.modeSelection;
    _resetOnlineState();
    notifyListeners();
  }

  // ── Online flow ─────────────────────────────────────────────────────────

  final _socket = SocketService();

  void _connectSocket() {
    _socket.connect(SocketCallbacks(
      onRoomCreated: _handleRoomUpdate,
      onRoomUpdated: _handleRoomUpdate,
      onRoomError: (msg) {
        _roomError = msg;
        notifyListeners();
      },
      onCountdown: (seconds) {
        _countdown = seconds;
        notifyListeners();
      },
      onCountdownCancelled: () {
        _countdown = null;
        notifyListeners();
      },
      onGameStarting: (data) {
        _impostorCount = data.impostorCount;
        _showRoleOnElimination = data.showRoleOnElimination;
        _impostorHasClue = data.impostorHasClue;
        _currentWord = WordEntry(
          id: 0,
          dificultad: Difficulty.facil,
          palabraReal: data.word,
          pistaImpostor: [data.clue],
        );
        _impostorClue = data.clue;
        _players = data.assignments.map((a) => Player(
              name: a.name,
              role: a.role == 'impostor' ? Role.impostor : Role.civil,
            )).toList();
        _firstSpeakerIndex = _players.indexWhere((p) => p.name == data.firstSpeaker);
        if (_firstSpeakerIndex < 0) _firstSpeakerIndex = 0;
        _roundNumber = 1;
        _countdown = null;
        _phase = GamePhase.onlineReveal;
        notifyListeners();
      },
      onDiscussionStarted: (data) {
        _onlineSpeakingOrder = data.speakingOrder;
        _onlineDiscussionDeadlineMs = data.deadlineMs;
        _onlineVoteCount = 0;
        _onlineVoteTotal = _players.where((p) => p.alive).length;
        _myOnlineVote = null;
        _roundNumber = data.roundNumber;
        _phase = GamePhase.onlineDiscussion;
        notifyListeners();
      },
      onVoteUpdate: (votedCount, totalCount) {
        _onlineVoteCount = votedCount;
        _onlineVoteTotal = totalCount;
        notifyListeners();
      },
      onVotingClosed: (data) {
        _votingClosedEliminated = data.eliminated;
        _votingClosedReason = data.reason;
        _votingTally = data.tally;
        if (data.eliminated != null) {
          final idx = _players.indexWhere((p) => p.name == data.eliminated);
          if (idx >= 0) {
            _players = _players.asMap().entries.map((e) {
              if (e.key == idx) return e.value.copyWith(alive: false);
              return e.value;
            }).toList();
            _lastEliminatedIndex = idx;
          }
        }
        _phase = GamePhase.onlineSuspense;
        notifyListeners();
      },
      onRoomReset: (room) {
        _handleRoomUpdate(room);
      },
      onRoomLeft: () {
        _phase = GamePhase.onlineName;
        _resetOnlineState();
        notifyListeners();
      },
    ));
  }

  void _handleRoomUpdate(RoomState room) {
    _roomCode = room.code;
    _lobbyPlayers = room.players;
    _impostorCount = room.settings.impostorCount;
    _showRoleOnElimination = room.settings.showRoleOnElimination;
    _impostorHasClue = room.settings.impostorHasClue;
    _countdown = room.countdown;
    _isHost = room.players.any((p) => p.name == _localPlayerName && p.isHost);
    _roomError = null;

    if (_phase != GamePhase.onlineLobby) {
      _phase = GamePhase.onlineLobby;
    }
    notifyListeners();
  }

  void createRoom(String playerName) {
    _localPlayerName = playerName;
    _roomError = null;
    _connectSocket();
    // Small delay to ensure socket is connected before emitting
    Future.delayed(const Duration(milliseconds: 300), () {
      _socket.createRoom(playerName);
    });
  }

  void joinRoom(String playerName, String code) {
    _localPlayerName = playerName;
    _roomError = null;
    _connectSocket();
    Future.delayed(const Duration(milliseconds: 300), () {
      _socket.joinRoom(code, playerName);
    });
  }

  void backToOnlineName() {
    _socket.leaveRoom();
    _socket.disconnect();
    _phase = GamePhase.onlineName;
    _resetOnlineState();
    notifyListeners();
  }

  void updateLobbySettings({int? impostors, bool? showRole, bool? hasClue}) {
    if (!_isHost) return;
    final settings = <String, dynamic>{};
    if (impostors != null) settings['impostorCount'] = impostors;
    if (showRole != null) settings['showRoleOnElimination'] = showRole;
    if (hasClue != null) settings['impostorHasClue'] = hasClue;
    _socket.updateSettings(_roomCode, settings);
  }

  void toggleReady() {
    _socket.toggleReady(_roomCode);
  }

  void clearRoomError() {
    _roomError = null;
    notifyListeners();
  }

  void castOnlineVote(String targetName) {
    _myOnlineVote = targetName;
    _socket.castVote(targetName);
    notifyListeners();
  }

  void retractOnlineVote() {
    _myOnlineVote = null;
    _socket.retractVote();
    notifyListeners();
  }

  void closeOnlineVoting() {
    _socket.closeVoting();
  }

  /// Called after the suspense screen finishes showing the result.
  void resolveOnlineSuspense() {
    if (_votingClosedEliminated != null) {
      _phase = GamePhase.onlineElimination;
    } else {
      // tie or no_votes → new round, compute speaking order locally
      _startNewOnlineRound();
    }
    notifyListeners();
  }

  /// Called after the online elimination reveal countdown (5s) ends.
  void resolveOnlineElimination() {
    final aliveImpostors = _players.where((p) => p.alive && p.role == Role.impostor).length;
    final aliveCivils = _players.where((p) => p.alive && p.role == Role.civil).length;

    if (aliveImpostors == 0 || aliveImpostors >= aliveCivils) {
      _phase = GamePhase.result;
    } else {
      _startNewOnlineRound();
    }
    notifyListeners();
  }

  void _startNewOnlineRound() {
    _roundNumber++;
    _myOnlineVote = null;
    _onlineVoteCount = 0;
    final alive = _players.where((p) => p.alive).map((p) => p.name).toList();
    _onlineVoteTotal = alive.length;
    final startIdx = _random.nextInt(alive.length);
    _onlineSpeakingOrder = [...alive.sublist(startIdx), ...alive.sublist(0, startIdx)];
    _onlineDiscussionDeadlineMs = DateTime.now().millisecondsSinceEpoch + 300000;
    _phase = GamePhase.onlineDiscussion;
  }

  void playAgain() {
    _socket.playAgain();
    // Transition happens when room_reset is received → _handleRoomUpdate
  }

  void leaveOnlineGame() {
    _socket.leaveRoom();
    _socket.disconnect();
    _phase = GamePhase.modeSelection;
    _resetOnlineState();
    _players = [];
    notifyListeners();
  }

  void _resetOnlineState() {
    _localPlayerName = '';
    _roomCode = '';
    _isHost = false;
    _lobbyPlayers = [];
    _countdown = null;
    _roomError = null;
  }

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

  void startVoting({bool timerExpired = false, int elapsedSeconds = 0}) {
    _timerExpired = timerExpired;
    _elapsedSeconds = elapsedSeconds;
    _phase = GamePhase.voting;
    notifyListeners();
  }

  void backToPlaying() {
    _phase = GamePhase.playing;
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

    // Always show elimination screen (with or without role reveal)
    _phase = GamePhase.elimination;
    notifyListeners();
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
      _elapsedSeconds = 0;
      _phase = GamePhase.playing;
      _roundNumber++;
    }
    notifyListeners();
  }

  void resetGame() {
    _socket.leaveRoom();
    _socket.disconnect();
    _phase = GamePhase.modeSelection;
    _resetOnlineState();
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
    _timerExpired = false;
    _elapsedSeconds = 0;
    _loadingError = null;
    notifyListeners();
  }
}

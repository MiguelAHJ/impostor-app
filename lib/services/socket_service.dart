import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

const String _wsUrl = String.fromEnvironment(
  'WS_URL',
  defaultValue: 'https://secret-word-social-backend.vercel.app',
);

/// Datos de un jugador en el lobby tal como vienen del servidor.
class LobbyPlayer {
  final String name;
  final bool isHost;
  final bool ready;

  const LobbyPlayer({
    required this.name,
    required this.isHost,
    required this.ready,
  });

  factory LobbyPlayer.fromJson(Map<String, dynamic> json) => LobbyPlayer(
        name: json['name'] as String,
        isHost: json['isHost'] as bool,
        ready: json['ready'] as bool,
      );
}

/// Configuración de la sala.
class RoomSettings {
  final int impostorCount;
  final bool showRoleOnElimination;
  final bool impostorHasClue;

  const RoomSettings({
    required this.impostorCount,
    required this.showRoleOnElimination,
    required this.impostorHasClue,
  });

  factory RoomSettings.fromJson(Map<String, dynamic> json) => RoomSettings(
        impostorCount: json['impostorCount'] as int,
        showRoleOnElimination: json['showRoleOnElimination'] as bool,
        impostorHasClue: json['impostorHasClue'] as bool,
      );
}

/// Snapshot completo de una sala.
class RoomState {
  final String code;
  final List<LobbyPlayer> players;
  final RoomSettings settings;
  final int? countdown;

  const RoomState({
    required this.code,
    required this.players,
    required this.settings,
    this.countdown,
  });

  factory RoomState.fromJson(Map<String, dynamic> json) => RoomState(
        code: json['code'] as String,
        players: (json['players'] as List)
            .map((p) => LobbyPlayer.fromJson(p as Map<String, dynamic>))
            .toList(),
        settings:
            RoomSettings.fromJson(json['settings'] as Map<String, dynamic>),
        countdown: json['countdown'] as int?,
      );
}

/// Payload recibido cuando el backend confirma el inicio del juego.
class OnlineGameStart {
  final String word;
  final String clue;
  final List<({String name, String role})> assignments;
  final String firstSpeaker;
  final int impostorCount;
  final bool showRoleOnElimination;
  final bool impostorHasClue;

  const OnlineGameStart({
    required this.word,
    required this.clue,
    required this.assignments,
    required this.firstSpeaker,
    required this.impostorCount,
    required this.showRoleOnElimination,
    required this.impostorHasClue,
  });

  factory OnlineGameStart.fromJson(Map<String, dynamic> json) => OnlineGameStart(
        word: json['word'] as String,
        clue: json['clue'] as String,
        assignments: (json['assignments'] as List)
            .map((a) => (
                  name: a['name'] as String,
                  role: a['role'] as String,
                ))
            .toList(),
        firstSpeaker: json['firstSpeaker'] as String,
        impostorCount: json['impostorCount'] as int,
        showRoleOnElimination: json['showRoleOnElimination'] as bool,
        impostorHasClue: json['impostorHasClue'] as bool,
      );
}

/// Datos de inicio de discusión.
class DiscussionStartedData {
  final List<String> speakingOrder;
  final int roundNumber;
  final int deadlineMs;

  const DiscussionStartedData({
    required this.speakingOrder,
    required this.roundNumber,
    required this.deadlineMs,
  });

  factory DiscussionStartedData.fromJson(Map<String, dynamic> json) =>
      DiscussionStartedData(
        speakingOrder: List<String>.from(json['speakingOrder'] as List),
        roundNumber: json['roundNumber'] as int,
        deadlineMs: (json['deadlineMs'] as num).toInt(),
      );
}

/// Resultado de la votación.
class VotingClosedData {
  final String? eliminated;
  final String reason; // 'majority' | 'tie' | 'no_votes'
  final Map<String, int> tally;

  const VotingClosedData({
    required this.eliminated,
    required this.reason,
    required this.tally,
  });

  factory VotingClosedData.fromJson(Map<String, dynamic> json) =>
      VotingClosedData(
        eliminated: json['eliminated'] as String?,
        reason: json['reason'] as String,
        tally: (json['tally'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
      );
}

/// Callbacks que el GameProvider registra para reaccionar a eventos del server.
class SocketCallbacks {
  final void Function(RoomState room) onRoomCreated;
  final void Function(RoomState room) onRoomUpdated;
  final void Function(String message) onRoomError;
  final void Function(int seconds) onCountdown;
  final void Function() onCountdownCancelled;
  final void Function(OnlineGameStart data) onGameStarting;
  final void Function(DiscussionStartedData data) onDiscussionStarted;
  final void Function(int votedCount, int totalCount) onVoteUpdate;
  final void Function(VotingClosedData data) onVotingClosed;
  final void Function(RoomState room) onRoomReset;
  final void Function() onRoomLeft;

  const SocketCallbacks({
    required this.onRoomCreated,
    required this.onRoomUpdated,
    required this.onRoomError,
    required this.onCountdown,
    required this.onCountdownCancelled,
    required this.onGameStarting,
    required this.onDiscussionStarted,
    required this.onVoteUpdate,
    required this.onVotingClosed,
    required this.onRoomReset,
    required this.onRoomLeft,
  });
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  SocketCallbacks? _callbacks;

  bool get isConnected => _socket?.connected ?? false;

  void connect(SocketCallbacks callbacks) {
    _callbacks = callbacks;

    _socket?.dispose();

    _socket = io.io(
      _wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) => debugPrint('[WS] Connected'))
      ..onDisconnect((_) => debugPrint('[WS] Disconnected'))
      ..onConnectError((err) => debugPrint('[WS] Connection error: $err'))
      ..on('room_created', (data) {
        final room = RoomState.fromJson(data as Map<String, dynamic>);
        _callbacks?.onRoomCreated(room);
      })
      ..on('room_updated', (data) {
        final room = RoomState.fromJson(data as Map<String, dynamic>);
        _callbacks?.onRoomUpdated(room);
      })
      ..on('room_error', (data) {
        final msg =
            (data is Map) ? (data['message'] ?? 'Error') as String : 'Error';
        _callbacks?.onRoomError(msg);
      })
      ..on('countdown', (data) {
        final seconds = (data as Map)['seconds'] as int;
        _callbacks?.onCountdown(seconds);
      })
      ..on('countdown_cancelled', (_) {
        _callbacks?.onCountdownCancelled();
      })
      ..on('game_starting', (data) {
        final payload = OnlineGameStart.fromJson(data as Map<String, dynamic>);
        _callbacks?.onGameStarting(payload);
      })
      ..on('discussion_started', (data) {
        final payload = DiscussionStartedData.fromJson(data as Map<String, dynamic>);
        _callbacks?.onDiscussionStarted(payload);
      })
      ..on('vote_update', (data) {
        final m = data as Map;
        _callbacks?.onVoteUpdate(
          (m['votedCount'] as num).toInt(),
          (m['totalCount'] as num).toInt(),
        );
      })
      ..on('voting_closed', (data) {
        final payload = VotingClosedData.fromJson(data as Map<String, dynamic>);
        _callbacks?.onVotingClosed(payload);
      })
      ..on('room_reset', (data) {
        final room = RoomState.fromJson(data as Map<String, dynamic>);
        _callbacks?.onRoomReset(room);
      })
      ..on('room_left', (_) {
        _callbacks?.onRoomLeft();
      });

    _socket!.connect();
  }

  void createRoom(String playerName) {
    _socket?.emit('create_room', {'playerName': playerName});
  }

  void joinRoom(String roomCode, String playerName) {
    _socket?.emit('join_room', {
      'roomCode': roomCode,
      'playerName': playerName,
    });
  }

  void updateSettings(String roomCode, Map<String, dynamic> settings) {
    _socket?.emit('update_settings', {
      'roomCode': roomCode,
      'settings': settings,
    });
  }

  void toggleReady(String roomCode) {
    _socket?.emit('toggle_ready', {'roomCode': roomCode});
  }

  void castVote(String targetName) {
    _socket?.emit('cast_vote', {'targetName': targetName});
  }

  void retractVote() {
    _socket?.emit('retract_vote');
  }

  void closeVoting() {
    _socket?.emit('close_voting');
  }

  void playAgain() {
    _socket?.emit('play_again');
  }

  void leaveRoom() {
    _socket?.emit('leave_room');
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _callbacks = null;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:quizzapp/network/message_models.dart';
import 'package:quizzapp/utils/constants.dart';

enum NetworkRole { host, client }

class ConnectedPlayer {
  final String address;
  final Socket socket;
  String? name;
  int? avatarId;

  /// Number of consecutive write failures. Reset on a successful write.
  /// After [_kMaxWriteFailures] in a row the host gives up on this client
  /// and closes the socket — keeps the broadcast loop healthy.
  int _writeFailures = 0;

  ConnectedPlayer({required this.address, required this.socket});
}

const int _kMaxWriteFailures = 3;

/// Maximum time we delay player-list broadcasts after a join/disconnect to
/// coalesce bursts. Keeps the host from re-encoding+resending the entire
/// player list on every single join during a 300-player rush.
const Duration _kPlayerListDebounce = Duration(milliseconds: 250);

class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  NetworkRole? _role;
  ServerSocket? _server;
  Socket? _clientSocket;

  final _incomingCtrl = StreamController<NetworkMessage>.broadcast();
  final _connectionCtrl = StreamController<String>.broadcast();
  final Map<String, ConnectedPlayer> _clients = {};

  Stream<NetworkMessage> get messages => _incomingCtrl.stream;
  Stream<String> get connectionEvents => _connectionCtrl.stream;
  Map<String, ConnectedPlayer> get clients => Map.unmodifiable(_clients);

  Future<void> startHost() async {
    _role = NetworkRole.host;
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, kHostPort);
    _server!.listen(_onClientConnect);
  }

  void _onClientConnect(Socket socket) {
    // Disable Nagle so small JSON messages go out immediately.
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);
    } catch (_) {}

    final addr = '${socket.remoteAddress.address}:${socket.remotePort}';
    final player = ConnectedPlayer(address: addr, socket: socket);
    _clients[addr] = player;
    _connectionCtrl.add('connected:$addr');

    _attachLineReader(
      socket,
      onMessage: _incomingCtrl.add,
      onDone: () {
        _clients.remove(addr);
        _connectionCtrl.add('disconnected:$addr');
        try {
          socket.destroy();
        } catch (_) {}
      },
      onError: () {
        _clients.remove(addr);
        _connectionCtrl.add('disconnected:$addr');
        try {
          socket.destroy();
        } catch (_) {}
      },
    );
  }

  Future<bool> connectToHost(String host) async {
    _role = NetworkRole.client;
    try {
      _clientSocket = await Socket.connect(host, kHostPort,
          timeout: const Duration(seconds: 5));
      try {
        _clientSocket!.setOption(SocketOption.tcpNoDelay, true);
      } catch (_) {}
      _attachLineReader(
        _clientSocket!,
        onMessage: _incomingCtrl.add,
        onDone: () => _connectionCtrl.add('disconnected:host'),
        onError: () => _connectionCtrl.add('error:host'),
      );
      _connectionCtrl.add('connected:host');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reads NDJSON-framed messages from [socket] and emits them via [onMessage].
  /// Handles partial lines correctly across chunk boundaries.
  void _attachLineReader(
    Socket socket, {
    required void Function(NetworkMessage) onMessage,
    required VoidCallback onDone,
    required VoidCallback onError,
  }) {
    final buffer = StringBuffer();
    socket.cast<List<int>>().transform(utf8.decoder).listen(
      (chunk) {
        buffer.write(chunk);
        final str = buffer.toString();
        final lines = str.split('\n');
        buffer.clear();
        if (lines.isNotEmpty && !str.endsWith('\n')) {
          buffer.write(lines.removeLast());
        }
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final msg = NetworkMessage.parse(trimmed);
          if (msg != null) onMessage(msg);
        }
      },
      onDone: onDone,
      onError: (_) => onError(),
      cancelOnError: false,
    );
  }

  /// Broadcasts [msg] to every connected client. Encodes once, writes many.
  /// Clients that fail repeatedly are dropped automatically.
  void sendToAll(NetworkMessage msg) {
    final bytes = utf8.encode(msg.encode());
    final dead = <String>[];
    for (final p in _clients.values) {
      if (!_writeBytes(p, bytes)) dead.add(p.address);
    }
    for (final addr in dead) {
      final p = _clients.remove(addr);
      if (p != null) {
        try {
          p.socket.destroy();
        } catch (_) {}
        _connectionCtrl.add('disconnected:$addr');
      }
    }
  }

  void sendTo(String address, NetworkMessage msg) {
    final p = _clients[address];
    if (p == null) return;
    final ok = _writeBytes(p, utf8.encode(msg.encode()));
    if (!ok) {
      _clients.remove(address);
      try {
        p.socket.destroy();
      } catch (_) {}
      _connectionCtrl.add('disconnected:$address');
    }
  }

  void sendToHost(NetworkMessage msg) {
    if (_clientSocket == null) return;
    try {
      _clientSocket!.add(utf8.encode(msg.encode()));
    } catch (_) {}
  }

  bool _writeBytes(ConnectedPlayer p, List<int> bytes) {
    try {
      p.socket.add(bytes);
      p._writeFailures = 0;
      return true;
    } catch (_) {
      p._writeFailures++;
      return p._writeFailures < _kMaxWriteFailures;
    }
  }

  // ── Throttled player-list broadcast ────────────────────────────────────
  // Coalesces bursts of join/disconnect events so we don't re-encode the
  // entire player list on every single join during a crowd surge.

  Timer? _playerListDebounce;
  List<Map<String, dynamic>>? _pendingPlayerList;

  /// Schedules a player-list broadcast. Multiple calls within
  /// [_kPlayerListDebounce] coalesce into one send.
  void scheduleBroadcastPlayerList(List<Map<String, dynamic>> players) {
    _pendingPlayerList = players;
    _playerListDebounce?.cancel();
    _playerListDebounce = Timer(_kPlayerListDebounce, () {
      final pending = _pendingPlayerList;
      _pendingPlayerList = null;
      if (pending == null) return;
      sendToAll(PlayerListMessage(players: pending));
    });
  }

  /// Forces any pending throttled broadcasts to flush immediately.
  /// Call before transitioning out of the lobby into the game.
  void flushPendingBroadcasts() {
    if (_playerListDebounce?.isActive == true) {
      _playerListDebounce?.cancel();
      final pending = _pendingPlayerList;
      _pendingPlayerList = null;
      if (pending != null) {
        sendToAll(PlayerListMessage(players: pending));
      }
    }
  }

  void kickPlayer(String address) {
    final p = _clients[address];
    if (p != null) {
      sendTo(address, PlayerKickedMessage(name: p.name ?? ''));
      try {
        p.socket.destroy();
      } catch (_) {}
      _clients.remove(address);
    }
  }

  Future<void> dispose() async {
    _playerListDebounce?.cancel();
    _playerListDebounce = null;
    _pendingPlayerList = null;
    try {
      await _server?.close();
    } catch (_) {}
    _server = null;
    try {
      await _clientSocket?.close();
    } catch (_) {}
    _clientSocket = null;
    for (final p in _clients.values) {
      try {
        p.socket.destroy();
      } catch (_) {}
    }
    _clients.clear();
    _role = null;
  }

  bool get isHost => _role == NetworkRole.host;
  bool get isClient => _role == NetworkRole.client;
  int get playerCount => _clients.length;
}

typedef VoidCallback = void Function();

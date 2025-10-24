import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:bloomee/model/jam_models.dart' as jam_models;
import 'package:bloomee/model/song_model.dart';
import 'package:bloomee/services/bloomee_player.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JamService {
  static final JamService _instance = JamService._internal();
  factory JamService() => _instance;
  JamService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _connectionSubscription;
  
  // Current session and user
  jam_models.JamSession? _currentSession;
  jam_models.JamUser? _currentUser;
  
  // Streams for real-time updates
  final BehaviorSubject<jam_models.JamSession?> _sessionSubject = BehaviorSubject<jam_models.JamSession?>();
  final BehaviorSubject<List<jam_models.JamMessage>> _messagesSubject = BehaviorSubject<List<jam_models.JamMessage>>.seeded([]);
  final BehaviorSubject<List<jam_models.JamSession>> _availableSessionsSubject = BehaviorSubject<List<jam_models.JamSession>>.seeded([]);
  final BehaviorSubject<bool> _isConnectedSubject = BehaviorSubject<bool>.seeded(false);
  
  // Event handlers
  final StreamController<jam_models.JamEvent> _eventController = StreamController<jam_models.JamEvent>.broadcast();
  
  // Dependencies
  late BloomeeMusicPlayer _player;
  late SharedPreferences _prefs;
  
  // Getters
  Stream<jam_models.JamSession?> get sessionStream => _sessionSubject.stream;
  Stream<List<jam_models.JamMessage>> get messagesStream => _messagesSubject.stream;
  Stream<List<jam_models.JamSession>> get availableSessionsStream => _availableSessionsSubject.stream;
  Stream<bool> get isConnectedStream => _isConnectedSubject.stream;
  Stream<jam_models.JamEvent> get eventStream => _eventController.stream;
  
  jam_models.JamSession? get currentSession => _currentSession;
  jam_models.JamUser? get currentUser => _currentUser;
  bool get isConnected => _isConnectedSubject.value;
  
  // Initialize the service
  Future<void> initialize(BloomeeMusicPlayer player) async {
    _player = player;
    _prefs = await SharedPreferences.getInstance();
    
    // Load saved user data
    await _loadUserData();
    
    // Connect to WebSocket server
    await _connectToServer();
    
    // Setup player event listeners
    _setupPlayerListeners();
  }
  
  Future<void> _loadUserData() async {
    final userId = _prefs.getString('jam_user_id');
    final userName = _prefs.getString('jam_user_name');
    
    if (userId != null && userName != null) {
      _currentUser = jam_models.JamUser(
        id: userId,
        name: userName,
        role: jam_models.JamUserRole.participant,
        joinedAt: DateTime.now(),
      );
    }
  }
  
  Future<void> _connectToServer() async {
    try {
      // In production, replace with your WebSocket server URL
      const serverUrl = 'wss://your-jam-server.com/ws';
      
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _connectionSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
      
      _isConnectedSubject.add(true);
      log('Connected to Jam server', name: 'JamService');
      
      // Send authentication if user exists
      if (_currentUser != null) {
        _sendMessage({
          'type': 'authenticate',
          'userId': _currentUser!.id,
          'userName': _currentUser!.name,
        });
      }
      
    } catch (e) {
      log('Failed to connect to Jam server: $e', name: 'JamService');
      _isConnectedSubject.add(false);
    }
  }
  
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'] as String;
      
      switch (type) {
        case 'session_update':
          _handleSessionUpdate(data);
          break;
        case 'message':
          _handleNewMessage(data);
          break;
        case 'sessions_list':
          _handleSessionsList(data);
          break;
        case 'sync_request':
          _handleSyncRequest(data);
          break;
        case 'sync_response':
          _handleSyncResponse(data);
          break;
        case 'error':
          _handleError(data['message']);
          break;
      }
    } catch (e) {
      log('Error handling message: $e', name: 'JamService');
    }
  }
  
  void _handleSessionUpdate(Map<String, dynamic> data) {
    final sessionData = data['session'];
    if (sessionData != null) {
      _currentSession = _parseSession(sessionData);
      _sessionSubject.add(_currentSession);
      
      // Sync playback if not the host
      if (_currentUser?.role != jam_models.JamUserRole.host && _currentSession != null) {
        _syncPlayback();
      }
    }
  }
  
  void _handleNewMessage(Map<String, dynamic> data) {
    final message = jam_models.JamMessage(
      id: data['id'],
      sessionId: data['sessionId'],
      userId: data['userId'],
      userName: data['userName'],
      message: data['message'],
      timestamp: DateTime.parse(data['timestamp']),
      type: jam_models.JamMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == data['messageType'],
        orElse: () => jam_models.JamMessageType.text,
      ),
    );
    
    final currentMessages = _messagesSubject.value;
    _messagesSubject.add([...currentMessages, message]);
  }
  
  void _handleSessionsList(Map<String, dynamic> data) {
    final sessionsData = data['sessions'] as List;
    final sessions = sessionsData.map((s) => _parseSession(s)).toList();
    _availableSessionsSubject.add(sessions);
  }
  
  void _handleSyncRequest(Map<String, dynamic> data) {
    // Send current playback state to requesting user
    _sendCurrentState();
  }
  
  void _handleSyncResponse(Map<String, dynamic> data) {
    // Apply received sync data
    final syncData = jam_models.JamSyncData(
      sessionId: data['sessionId'],
      currentTrackId: data['currentTrackId'],
      position: data['position'] != null ? Duration(milliseconds: data['position']) : null,
      isPlaying: data['isPlaying'],
      queue: List<String>.from(data['queue']),
      timestamp: DateTime.parse(data['timestamp']),
    );
    
    _applySyncData(syncData);
  }
  
  void _handleError(dynamic error) {
    log('Jam service error: $error', name: 'JamService');
    _eventController.add(jam_models.JamEvent(
      id: const Uuid().v4(),
      sessionId: _currentSession?.id ?? '',
      type: jam_models.JamEventType.error,
      data: {'error': error.toString()},
      timestamp: DateTime.now(),
    ));
  }
  
  void _handleDisconnection() {
    _isConnectedSubject.add(false);
    log('Disconnected from Jam server', name: 'JamService');
    
    // Attempt to reconnect after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (!isConnected) {
        _connectToServer();
      }
    });
  }
  
  // Public methods
  Future<void> setUser(String name, {String? avatar}) async {
    final userId = const Uuid().v4();
    _currentUser = jam_models.JamUser(
      id: userId,
      name: name,
      avatar: avatar,
      role: jam_models.JamUserRole.participant,
      joinedAt: DateTime.now(),
    );
    
    // Save user data
    await _prefs.setString('jam_user_id', userId);
    await _prefs.setString('jam_user_name', name);
    if (avatar != null) {
      await _prefs.setString('jam_user_avatar', avatar);
    }
    
    // Reconnect with new user data
    if (isConnected) {
      _sendMessage({
        'type': 'authenticate',
        'userId': userId,
        'userName': name,
        'avatar': avatar,
      });
    }
  }
  
  Future<jam_models.JamSession> createSession({
    required String name,
    String? description,
    bool isPrivate = false,
    String? password,
    int maxParticipants = 10,
  }) async {
    if (_currentUser == null) {
      throw Exception('User must be set before creating a session');
    }
    
    final sessionId = const Uuid().v4();
    final session = jam_models.JamSession(
      id: sessionId,
      name: name,
      description: description,
      hostId: _currentUser!.id,
      participants: [_currentUser!],
      status: jam_models.JamSessionStatus.active,
      createdAt: DateTime.now(),
      isPrivate: isPrivate,
      password: password,
      maxParticipants: maxParticipants,
    );
    
    _sendMessage({
      'type': 'create_session',
      'session': _sessionToMap(session),
    });
    
    _currentSession = session;
    _sessionSubject.add(session);
    
    return session;
  }
  
  Future<void> joinSession(String sessionId, {String? password}) async {
    if (_currentUser == null) {
      throw Exception('User must be set before joining a session');
    }
    
    _sendMessage({
      'type': 'join_session',
      'sessionId': sessionId,
      'userId': _currentUser!.id,
      'password': password,
    });
  }
  
  Future<void> leaveSession() async {
    if (_currentSession == null) return;
    
    _sendMessage({
      'type': 'leave_session',
      'sessionId': _currentSession!.id,
      'userId': _currentUser!.id,
    });
    
    _currentSession = null;
    _sessionSubject.add(null);
    _messagesSubject.add([]);
  }
  
  Future<void> sendMessage(String message) async {
    if (_currentSession == null || _currentUser == null) return;
    
    _sendMessage({
      'type': 'send_message',
      'sessionId': _currentSession!.id,
      'userId': _currentUser!.id,
      'userName': _currentUser!.name,
      'message': message,
    });
  }
  
  Future<void> addTrackToQueue(jam_models.MediaItemModel track) async {
    if (_currentSession == null || _currentUser == null) return;
    
    _sendMessage({
      'type': 'add_track',
      'sessionId': _currentSession!.id,
      'userId': _currentUser!.id,
      'track': {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'album': track.album,
        'duration': track.duration?.inSeconds,
        'image': track.image,
      },
    });
  }
  
  Future<void> removeTrackFromQueue(String trackId) async {
    if (_currentSession == null || _currentUser == null) return;
    
    _sendMessage({
      'type': 'remove_track',
      'sessionId': _currentSession!.id,
      'userId': _currentUser!.id,
      'trackId': trackId,
    });
  }
  
  Future<void> requestSessionsList() async {
    _sendMessage({'type': 'get_sessions'});
  }
  
  // Player integration methods
  void _setupPlayerListeners() {
    // Listen to player state changes and broadcast to session
    _player.playbackState.listen((state) {
      if (_currentSession != null && _currentUser?.role == jam_models.JamUserRole.host) {
        _broadcastPlaybackState();
      }
    });
    
    _player.mediaItem.listen((mediaItem) {
      if (_currentSession != null && _currentUser?.role == jam_models.JamUserRole.host) {
        // Convert MediaItem to MediaItemModel
        final mediaItemModel = jam_models.MediaItemModel(
          id: mediaItem.id,
          title: mediaItem.title,
          artist: mediaItem.artist ?? 'Unknown',
          album: mediaItem.album ?? 'Unknown',
          image: mediaItem.artUri?.toString(),
          duration: mediaItem.duration,
        );
        _broadcastTrackChange(mediaItemModel);
      }
    });
  }
  
  void _broadcastPlaybackState() {
    if (_currentSession == null) return;
    
    _sendMessage({
      'type': 'playback_state',
      'sessionId': _currentSession!.id,
      'isPlaying': _player.playbackState.value.playing,
      'position': _player.playbackState.value.position.inMilliseconds,
    });
  }
  
  void _broadcastTrackChange(jam_models.MediaItemModel? mediaItem) {
    if (_currentSession == null || mediaItem == null) return;
    
    _sendMessage({
      'type': 'track_change',
      'sessionId': _currentSession!.id,
      'trackId': mediaItem.id,
      'title': mediaItem.title,
      'artist': mediaItem.artist,
    });
  }
  
  void _sendCurrentState() {
    if (_currentSession == null) return;
    
    final currentMedia = _player.currentMedia;
    final queue = _player.queue.value.map((item) => item.id).toList();
    
    _sendMessage({
      'type': 'sync_response',
      'sessionId': _currentSession!.id,
      'currentTrackId': currentMedia.id,
      'position': _player.playbackState.value.position.inMilliseconds,
      'isPlaying': _player.playbackState.value.playing,
      'queue': queue,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  void _syncPlayback() {
    if (_currentSession == null) return;
    
    _sendMessage({
      'type': 'sync_request',
      'sessionId': _currentSession!.id,
    });
  }
  
  void _applySyncData(jam_models.JamSyncData syncData) {
    // Apply sync data to player
    if (syncData.currentTrackId != null) {
      // Find and play the track
      final queue = _player.queue.value;
      final trackIndex = queue.indexWhere((item) => item.id == syncData.currentTrackId);
      
      if (trackIndex != -1) {
        _player.skipToQueueItem(trackIndex);
        
        if (syncData.position != null) {
          _player.seek(syncData.position!);
        }
        
        if (syncData.isPlaying) {
          _player.play();
        } else {
          _player.pause();
        }
      }
    }
  }
  
  // Helper methods
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(json.encode(message));
    }
  }
  
  jam_models.JamSession _parseSession(Map<String, dynamic> data) {
    return jam_models.JamSession(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      hostId: data['hostId'],
      participants: (data['participants'] as List)
          .map((p) => jam_models.JamUser(
                id: p['id'],
                name: p['name'],
                avatar: p['avatar'],
                role: jam_models.JamUserRole.values.firstWhere(
                  (e) => e.toString().split('.').last == p['role'],
                  orElse: () => jam_models.JamUserRole.participant,
                ),
                joinedAt: DateTime.parse(p['joinedAt']),
                isOnline: p['isOnline'] ?? true,
              ))
          .toList(),
      status: jam_models.JamSessionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => jam_models.JamSessionStatus.active,
      ),
      createdAt: DateTime.parse(data['createdAt']),
      lastActivity: data['lastActivity'] != null ? DateTime.parse(data['lastActivity']) : null,
      currentTrackId: data['currentTrackId'],
      currentPosition: data['currentPosition'] != null ? Duration(milliseconds: data['currentPosition']) : null,
      isPrivate: data['isPrivate'] ?? false,
      password: data['password'],
      maxParticipants: data['maxParticipants'] ?? 10,
    );
  }
  
  Map<String, dynamic> _sessionToMap(jam_models.JamSession session) {
    return {
      'id': session.id,
      'name': session.name,
      'description': session.description,
      'hostId': session.hostId,
      'participants': session.participants.map((p) => {
        'id': p.id,
        'name': p.name,
        'avatar': p.avatar,
        'role': p.role.toString().split('.').last,
        'joinedAt': p.joinedAt.toIso8601String(),
        'isOnline': p.isOnline,
      }).toList(),
      'status': session.status.toString().split('.').last,
      'createdAt': session.createdAt.toIso8601String(),
      'lastActivity': session.lastActivity?.toIso8601String(),
      'currentTrackId': session.currentTrackId,
      'currentPosition': session.currentPosition?.inMilliseconds,
      'isPrivate': session.isPrivate,
      'password': session.password,
      'maxParticipants': session.maxParticipants,
    };
  }
  
  // Cleanup
  Future<void> dispose() async {
    await _connectionSubscription?.cancel();
    await _channel?.sink.close();
    await _sessionSubject.close();
    await _messagesSubject.close();
    await _availableSessionsSubject.close();
    await _isConnectedSubject.close();
    await _eventController.close();
  }
}



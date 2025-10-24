import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum JamSessionStatus {
  active,
  paused,
  ended,
  waiting
}

enum JamUserRole {
  host,
  participant
}

class JamUser extends Equatable {
  final String id;
  final String name;
  final String? avatar;
  final JamUserRole role;
  final DateTime joinedAt;
  final bool isOnline;

  const JamUser({
    required this.id,
    required this.name,
    this.avatar,
    required this.role,
    required this.joinedAt,
    this.isOnline = true,
  });

  @override
  List<Object?> get props => [id, name, avatar, role, joinedAt, isOnline];

  JamUser copyWith({
    String? id,
    String? name,
    String? avatar,
    JamUserRole? role,
    DateTime? joinedAt,
    bool? isOnline,
  }) {
    return JamUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class JamSession extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String hostId;
  final List<JamUser> participants;
  final JamSessionStatus status;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final String? currentTrackId;
  final Duration? currentPosition;
  final bool isPrivate;
  final String? password;
  final int maxParticipants;

  const JamSession({
    required this.id,
    required this.name,
    this.description,
    required this.hostId,
    required this.participants,
    required this.status,
    required this.createdAt,
    this.lastActivity,
    this.currentTrackId,
    this.currentPosition,
    this.isPrivate = false,
    this.password,
    this.maxParticipants = 10,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        hostId,
        participants,
        status,
        createdAt,
        lastActivity,
        currentTrackId,
        currentPosition,
        isPrivate,
        password,
        maxParticipants,
      ];

  JamSession copyWith({
    String? id,
    String? name,
    String? description,
    String? hostId,
    List<JamUser>? participants,
    JamSessionStatus? status,
    DateTime? createdAt,
    DateTime? lastActivity,
    String? currentTrackId,
    Duration? currentPosition,
    bool? isPrivate,
    String? password,
    int? maxParticipants,
  }) {
    return JamSession(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      hostId: hostId ?? this.hostId,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      currentTrackId: currentTrackId ?? this.currentTrackId,
      currentPosition: currentPosition ?? this.currentPosition,
      isPrivate: isPrivate ?? this.isPrivate,
      password: password ?? this.password,
      maxParticipants: maxParticipants ?? this.maxParticipants,
    );
  }

  bool get isFull => participants.length >= maxParticipants;
  bool get canJoin => !isFull && status == JamSessionStatus.active;
}

class JamMessage extends Equatable {
  final String id;
  final String sessionId;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;
  final JamMessageType type;

  const JamMessage({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
    this.type = JamMessageType.text,
  });

  @override
  List<Object?> get props => [id, sessionId, userId, userName, message, timestamp, type];
}

enum JamMessageType {
  text,
  trackAdded,
  trackRemoved,
  userJoined,
  userLeft,
  sessionEnded,
  system
}

class JamEvent extends Equatable {
  final String id;
  final String sessionId;
  final JamEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? userId;

  const JamEvent({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.data,
    required this.timestamp,
    this.userId,
  });

  @override
  List<Object?> get props => [id, sessionId, type, data, timestamp, userId];
}

enum JamEventType {
  // Session events
  sessionCreated,
  sessionJoined,
  sessionLeft,
  sessionEnded,
  
  // Playback events
  play,
  pause,
  seek,
  trackChanged,
  queueUpdated,
  
  // User events
  userJoined,
  userLeft,
  userRoleChanged,
  
  // Chat events
  messageSent,
  
  // System events
  syncRequest,
  syncResponse,
  error
}

class JamSyncData extends Equatable {
  final String sessionId;
  final String? currentTrackId;
  final Duration? position;
  final bool isPlaying;
  final List<String> queue;
  final DateTime timestamp;

  const JamSyncData({
    required this.sessionId,
    this.currentTrackId,
    this.position,
    required this.isPlaying,
    required this.queue,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [sessionId, currentTrackId, position, isPlaying, queue, timestamp];
}

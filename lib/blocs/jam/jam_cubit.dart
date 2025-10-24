import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bloomee/model/jam_models.dart';
import 'package:bloomee/model/song_model.dart' as song_model;
import 'package:bloomee/services/jam_service.dart';
import 'package:bloomee/services/bloomee_player.dart';

// Events
abstract class JamEvent extends Equatable {
  const JamEvent();

  @override
  List<Object?> get props => [];
}

class JamInitialize extends JamEvent {
  const JamInitialize();
}

class JamSetUser extends JamEvent {
  final String name;
  final String? avatar;

  const JamSetUser({required this.name, this.avatar});

  @override
  List<Object?> get props => [name, avatar];
}

class JamCreateSession extends JamEvent {
  final String name;
  final String? description;
  final bool isPrivate;
  final String? password;
  final int maxParticipants;

  const JamCreateSession({
    required this.name,
    this.description,
    this.isPrivate = false,
    this.password,
    this.maxParticipants = 10,
  });

  @override
  List<Object?> get props => [name, description, isPrivate, password, maxParticipants];
}

class JamJoinSession extends JamEvent {
  final String sessionId;
  final String? password;

  const JamJoinSession({required this.sessionId, this.password});

  @override
  List<Object?> get props => [sessionId, password];
}

class JamLeaveSession extends JamEvent {
  const JamLeaveSession();
}

class JamSendMessage extends JamEvent {
  final String message;

  const JamSendMessage({required this.message});

  @override
  List<Object?> get props => [message];
}

class JamAddTrack extends JamEvent {
  final MediaItemModel track;

  const JamAddTrack({required this.track});

  @override
  List<Object?> get props => [track];
}

class JamRemoveTrack extends JamEvent {
  final String trackId;

  const JamRemoveTrack({required this.trackId});

  @override
  List<Object?> get props => [trackId];
}

class JamLoadSessions extends JamEvent {
  const JamLoadSessions();
}

// States
abstract class JamState extends Equatable {
  const JamState();

  @override
  List<Object?> get props => [];
}

class JamInitial extends JamState {
  const JamInitial();
}

class JamLoading extends JamState {
  const JamLoading();
}

class JamConnected extends JamState {
  final JamUser user;

  const JamConnected({required this.user});

  @override
  List<Object?> get props => [user];
}

class JamSessionsLoaded extends JamState {
  final List<JamSession> sessions;

  const JamSessionsLoaded({required this.sessions});

  @override
  List<Object?> get props => [sessions];
}

class JamSessionCreated extends JamState {
  final JamSession session;

  const JamSessionCreated({required this.session});

  @override
  List<Object?> get props => [session];
}

class JamSessionJoined extends JamState {
  final JamSession session;

  const JamSessionJoined({required this.session});

  @override
  List<Object?> get props => [session];
}

class JamSessionActive extends JamState {
  final JamSession session;
  final List<MediaItemModel> queue;
  final List<JamMessage> messages;

  const JamSessionActive({
    required this.session,
    required this.queue,
    required this.messages,
  });

  @override
  List<Object?> get props => [session, queue, messages];
}

class JamSessionLeft extends JamState {
  const JamSessionLeft();
}

class JamError extends JamState {
  final String message;

  const JamError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Cubit
class JamCubit extends Cubit<JamState> {
  final JamService _jamService;
  final BloomeeMusicPlayer _player;
  StreamSubscription? _sessionSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _sessionsSubscription;

  JamCubit({
    required JamService jamService,
    required BloomeeMusicPlayer player,
  })  : _jamService = jamService,
        _player = player,
        super(const JamInitial());

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    _messagesSubscription?.cancel();
    _sessionsSubscription?.cancel();
    return super.close();
  }

  Future<void> initialize() async {
    emit(const JamLoading());
    
    try {
      await _jamService.initialize(_player);
      
      // Listen to session changes
      _sessionSubscription = _jamService.sessionStream.listen((session) {
        if (session != null) {
          if (state is JamSessionActive) {
            emit(JamSessionActive(
              session: session,
              queue: (state as JamSessionActive).queue,
              messages: (state as JamSessionActive).messages,
            ));
          } else {
            emit(JamSessionJoined(session: session));
          }
        } else {
          emit(const JamSessionLeft());
        }
      });

      // Listen to messages
      _messagesSubscription = _jamService.messagesStream.listen((messages) {
        if (state is JamSessionActive) {
          emit(JamSessionActive(
            session: (state as JamSessionActive).session,
            queue: (state as JamSessionActive).queue,
            messages: messages,
          ));
        }
      });

      // Listen to available sessions
      _sessionsSubscription = _jamService.availableSessionsStream.listen((sessions) {
        emit(JamSessionsLoaded(sessions: sessions));
      });

      // Check if user is already set
      if (_jamService.currentUser != null) {
        emit(JamConnected(user: _jamService.currentUser!));
      } else {
        emit(const JamInitial());
      }
    } catch (e) {
      emit(JamError(message: 'Failed to initialize Jam service: $e'));
    }
  }

  Future<void> setUser(String name, {String? avatar}) async {
    try {
      await _jamService.setUser(name, avatar: avatar);
      final user = _jamService.currentUser!;
      emit(JamConnected(user: user));
    } catch (e) {
      emit(JamError(message: 'Failed to set user: $e'));
    }
  }

  Future<void> createSession({
    required String name,
    String? description,
    bool isPrivate = false,
    String? password,
    int maxParticipants = 10,
  }) async {
    try {
      emit(const JamLoading());
      final session = await _jamService.createSession(
        name: name,
        description: description,
        isPrivate: isPrivate,
        password: password,
        maxParticipants: maxParticipants,
      );
      emit(JamSessionCreated(session: session));
    } catch (e) {
      emit(JamError(message: 'Failed to create session: $e'));
    }
  }

  Future<void> joinSession(String sessionId, {String? password}) async {
    try {
      emit(const JamLoading());
      await _jamService.joinSession(sessionId, password: password);
    } catch (e) {
      emit(JamError(message: 'Failed to join session: $e'));
    }
  }

  Future<void> leaveSession() async {
    try {
      await _jamService.leaveSession();
      emit(const JamSessionLeft());
    } catch (e) {
      emit(JamError(message: 'Failed to leave session: $e'));
    }
  }

  Future<void> sendMessage(String message) async {
    try {
      await _jamService.sendMessage(message);
    } catch (e) {
      emit(JamError(message: 'Failed to send message: $e'));
    }
  }

  Future<void> addTrackToQueue(MediaItemModel track) async {
    try {
      await _jamService.addTrackToQueue(track);
    } catch (e) {
      emit(JamError(message: 'Failed to add track: $e'));
    }
  }

  Future<void> removeTrackFromQueue(String trackId) async {
    try {
      await _jamService.removeTrackFromQueue(trackId);
    } catch (e) {
      emit(JamError(message: 'Failed to remove track: $e'));
    }
  }

  Future<void> loadAvailableSessions() async {
    try {
      emit(const JamLoading());
      await _jamService.requestSessionsList();
    } catch (e) {
      emit(JamError(message: 'Failed to load sessions: $e'));
    }
  }
}



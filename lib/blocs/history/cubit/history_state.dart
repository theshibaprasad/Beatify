part of 'history_cubit.dart';

class HistoryState {
  MediaPlaylist mediaPlaylist;
  HistoryState({
    required this.mediaPlaylist,
  });

  HistoryState copyWith({
    MediaPlaylist? mediaPlaylist,
  }) {
    return HistoryState(
      mediaPlaylist: mediaPlaylist ?? this.mediaPlaylist,
    );
  }
}

class HistoryInitial extends HistoryState {
  const HistoryInitial()
      : super(mediaPlaylist: const MediaPlaylist(playlistName: "", mediaItems: []));
}

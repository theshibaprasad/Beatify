import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Bloomee/blocs/jam/jam_cubit.dart';
import 'package:Bloomee/model/jam_models.dart';
import 'package:Bloomee/theme_data/default.dart';

class JamSessionScreen extends StatefulWidget {
  const JamSessionScreen({super.key});

  @override
  State<JamSessionScreen> createState() => _JamSessionScreenState();
}

class _JamSessionScreenState extends State<JamSessionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JamCubit, JamState>(
      listener: (context, state) {
        if (state is JamError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is JamSessionLeft) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        if (state is JamSessionJoined || state is JamSessionActive) {
          final session = state is JamSessionJoined ? state.session : (state as JamSessionActive).session;
          
          return Scaffold(
            backgroundColor: Default_Theme.primaryColor,
            appBar: AppBar(
              title: Text(
                session.name,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Default_Theme.accentColor2,
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'leave':
                        context.read<JamCubit>().leaveSession();
                        break;
                      case 'settings':
                        _showSessionSettings(context, session);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('Session Settings'),
                    ),
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Leave Session'),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.queue_music), text: 'Queue'),
                  Tab(icon: Icon(Icons.people), text: 'Participants'),
                  Tab(icon: Icon(Icons.chat), text: 'Chat'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildQueueTab(context, session),
                _buildParticipantsTab(context, session),
                _buildChatTab(context, session),
              ],
            ),
          );
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildQueueTab(BuildContext context, JamSession session) {
    return BlocBuilder<JamCubit, JamState>(
      builder: (context, state) {
        final queue = state is JamSessionActive ? state.queue : <MediaItemModel>[];
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: queue.length,
          itemBuilder: (context, index) {
            final track = queue[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Default_Theme.cardColor,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: track.image != null 
                      ? NetworkImage(track.image!) 
                      : null,
                  child: track.image == null 
                      ? const Icon(Icons.music_note) 
                      : null,
                ),
                title: Text(
                  track.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${track.artist} • ${track.album}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: () {
                        // Play track
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        context.read<JamCubit>().removeTrackFromQueue(track.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildParticipantsTab(BuildContext context, JamSession session) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: session.participants.length,
      itemBuilder: (context, index) {
        final participant = session.participants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Default_Theme.cardColor,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Default_Theme.accentColor2,
              child: Text(
                participant.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              participant.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              participant.role.toString().split('.').last,
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  participant.isOnline ? Icons.circle : Icons.circle_outlined,
                  color: participant.isOnline ? Colors.green : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 8),
                if (participant.role == JamUserRole.host)
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatTab(BuildContext context, JamSession session) {
    return BlocBuilder<JamCubit, JamState>(
      builder: (context, state) {
        final messages = state is JamSessionActive ? state.messages : <JamMessage>[];
        
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(context, message);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Default_Theme.cardColor,
                border: Border(
                  top: BorderSide(color: Colors.white24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Default_Theme.accentColor1),
                        ),
                      ),
                      onSubmitted: (text) {
                        if (text.isNotEmpty) {
                          context.read<JamCubit>().sendMessage(text);
                          _messageController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      final text = _messageController.text;
                      if (text.isNotEmpty) {
                        context.read<JamCubit>().sendMessage(text);
                        _messageController.clear();
                      }
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, JamMessage message) {
    final isSystemMessage = message.type != JamMessageType.text;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isSystemMessage 
                ? Colors.grey 
                : Default_Theme.accentColor2,
            child: Icon(
              isSystemMessage ? Icons.info : Icons.person,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSystemMessage)
                  Text(
                    message.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  message.message,
                  style: TextStyle(
                    color: isSystemMessage ? Colors.white70 : Colors.white,
                    fontStyle: isSystemMessage ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionSettings(BuildContext context, JamSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Session Name'),
              subtitle: Text(session.name),
            ),
            ListTile(
              title: const Text('Participants'),
              subtitle: Text('${session.participants.length}/${session.maxParticipants}'),
            ),
            ListTile(
              title: const Text('Privacy'),
              subtitle: Text(session.isPrivate ? 'Private' : 'Public'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}



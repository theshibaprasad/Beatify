import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloomee/blocs/jam/jam_cubit.dart';
import 'package:bloomee/model/jam_models.dart';
import 'package:bloomee/screens/jam/create_jam_screen.dart';
import 'package:bloomee/screens/jam/join_jam_screen.dart';
import 'package:bloomee/screens/jam/jam_session_screen.dart';
import 'package:bloomee/theme_data/default.dart';

class JamHomeScreen extends StatefulWidget {
  const JamHomeScreen({super.key});

  @override
  State<JamHomeScreen> createState() => _JamHomeScreenState();
}

class _JamHomeScreenState extends State<JamHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<JamCubit>().loadAvailableSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultTheme.primaryColor,
      appBar: AppBar(
        title: const Text(
          'Jam Sessions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DefaultTheme.accentColor2,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<JamCubit>().loadAvailableSessions(),
          ),
        ],
      ),
      body: BlocConsumer<JamCubit, JamState>(
        listener: (context, state) {
          if (state is JamSessionJoined) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const JamSessionScreen(),
              ),
            );
          } else if (state is JamError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is JamLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          return Column(
            children: [
              // Quick Actions
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCreateJamDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Jam'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DefaultTheme.accentColor2,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showJoinJamDialog(context),
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join Jam'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DefaultTheme.accentColor1,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Available Sessions
              Expanded(
                child: state is JamSessionsLoaded
                    ? _buildSessionsList(context, state.sessions)
                    : const Center(
                        child: Text(
                          'No sessions available',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSessionsList(BuildContext context, List<JamSession> sessions) {
    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          'No active sessions found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(context, session);
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, JamSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: DefaultTheme.cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: DefaultTheme.accentColor2,
          child: Text(
            session.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          session.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session.description != null)
              Text(
                session.description!,
                style: const TextStyle(color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.participants.length}/${session.maxParticipants}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 16),
                Icon(
                  session.isPrivate ? Icons.lock : Icons.public,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  session.isPrivate ? 'Private' : 'Public',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        trailing: session.canJoin
            ? ElevatedButton(
                onPressed: () => _joinSession(context, session),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DefaultTheme.accentColor1,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Join'),
              )
            : const Text(
                'Full',
                style: TextStyle(color: Colors.red),
              ),
        onTap: () => _showSessionDetails(context, session),
      ),
    );
  }

  void _showCreateJamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateJamDialog(),
    );
  }

  void _showJoinJamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const JoinJamDialog(),
    );
  }

  void _joinSession(BuildContext context, JamSession session) {
    context.read<JamCubit>().joinSession(session.id);
  }

  void _showSessionDetails(BuildContext context, JamSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session.description != null)
              Text('Description: ${session.description}'),
            Text('Participants: ${session.participants.length}/${session.maxParticipants}'),
            Text('Status: ${session.status.toString().split('.').last}'),
            Text('Created: ${_formatDate(session.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (session.canJoin)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _joinSession(context, session);
              },
              child: const Text('Join'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}



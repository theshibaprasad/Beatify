import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Bloomee/blocs/jam/jam_cubit.dart';
import 'package:Bloomee/theme_data/default.dart';

class JoinJamDialog extends StatefulWidget {
  const JoinJamDialog({super.key});

  @override
  State<JoinJamDialog> createState() => _JoinJamDialogState();
}

class _JoinJamDialogState extends State<JoinJamDialog> {
  final _sessionIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usePassword = false;

  @override
  void dispose() {
    _sessionIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JamCubit, JamState>(
      listener: (context, state) {
        if (state is JamSessionJoined) {
          Navigator.pop(context);
          // Navigate to session screen
        } else if (state is JamError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: Default_Theme.cardColor,
        title: const Text(
          'Join Jam Session',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Session ID
            TextFormField(
              controller: _sessionIdController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Session ID',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Enter session ID or invite link',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Default_Theme.accentColor1),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a session ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password option
            CheckboxListTile(
              title: const Text(
                'Session has password',
                style: TextStyle(color: Colors.white),
              ),
              value: _usePassword,
              onChanged: (value) {
                setState(() {
                  _usePassword = value ?? false;
                });
              },
              activeColor: Default_Theme.accentColor1,
            ),

            if (_usePassword) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Default_Theme.accentColor1),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (_usePassword && (value == null || value.isEmpty)) {
                    return 'Please enter the password';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          BlocBuilder<JamCubit, JamState>(
            builder: (context, state) {
              final isLoading = state is JamLoading;
              return ElevatedButton(
                onPressed: isLoading ? null : _joinSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Default_Theme.accentColor1,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Join Session'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _joinSession() {
    final sessionId = _sessionIdController.text.trim();
    if (sessionId.isNotEmpty) {
      context.read<JamCubit>().joinSession(
        sessionId,
        password: _usePassword ? _passwordController.text : null,
      );
    }
  }
}



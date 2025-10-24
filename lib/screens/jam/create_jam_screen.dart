import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Bloomee/blocs/jam/jam_cubit.dart';
import 'package:Bloomee/theme_data/default.dart';

class CreateJamDialog extends StatefulWidget {
  const CreateJamDialog({super.key});

  @override
  State<CreateJamDialog> createState() => _CreateJamDialogState();
}

class _CreateJamDialogState extends State<CreateJamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPrivate = false;
  int _maxParticipants = 10;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JamCubit, JamState>(
      listener: (context, state) {
        if (state is JamSessionCreated) {
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
          'Create Jam Session',
          style: TextStyle(color: Colors.white),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Session Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Session Name',
                    labelStyle: TextStyle(color: Colors.white70),
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
                      return 'Please enter a session name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Default_Theme.accentColor1),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Privacy Settings
                Card(
                  color: Default_Theme.primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Privacy Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text(
                            'Private Session',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Only people with the link can join',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _isPrivate,
                          onChanged: (value) {
                            setState(() {
                              _isPrivate = value;
                            });
                          },
                          activeColor: Default_Theme.accentColor1,
                        ),
                        if (_isPrivate) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Password (Optional)',
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
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Max Participants
                Card(
                  color: Default_Theme.primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Max Participants',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _maxParticipants.toDouble(),
                          min: 2,
                          max: 20,
                          divisions: 18,
                          activeColor: Default_Theme.accentColor1,
                          onChanged: (value) {
                            setState(() {
                              _maxParticipants = value.round();
                            });
                          },
                        ),
                        Text(
                          '$_maxParticipants participants',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                onPressed: isLoading ? null : _createSession,
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
                    : const Text('Create Session'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _createSession() {
    if (_formKey.currentState!.validate()) {
      context.read<JamCubit>().createSession(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
        isPrivate: _isPrivate,
        password: _isPrivate && _passwordController.text.isNotEmpty 
            ? _passwordController.text 
            : null,
        maxParticipants: _maxParticipants,
      );
    }
  }
}


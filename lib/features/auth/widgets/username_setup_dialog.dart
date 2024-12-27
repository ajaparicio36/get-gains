// lib/features/auth/widgets/username_setup_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/constants/colors.dart';
import '../../data/models/user_model.dart';

class UsernameSetupDialog extends StatefulWidget {
  const UsernameSetupDialog({super.key});

  @override
  State<UsernameSetupDialog> createState() => _UsernameSetupDialogState();
}

class _UsernameSetupDialogState extends State<UsernameSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  // Check if username is unique
  Future<bool> _isUsernameUnique(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .get();
    return querySnapshot.docs.isEmpty;
  }

  // Save username to Firestore
  Future<void> _saveUsername(String username) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userModel = UserModel(
      uid: user.uid,
      email: user.email!,
      username: username.toLowerCase(),
      displayName: username,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap());
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final isUnique = await _isUsernameUnique(username);
      if (!isUnique) {
        setState(() {
          _errorMessage = 'Username already exists';
          _isSubmitting = false;
        });
        return;
      }

      await _saveUsername(username);
      if (mounted) Navigator.pop(context);
    } catch (e, stackTrace) {
      print('Error saving username: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}'; // Show actual error
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent closing by back button
      child: AlertDialog(
        title: const Text('Choose Your Username'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose a unique username for your account.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                enabled: !_isSubmitting,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  if (value.length > 20) {
                    return 'Username must be less than 20 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return 'Username can only contain letters, numbers, and underscores';
                  }
                  return null;
                },
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppColors.errorColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

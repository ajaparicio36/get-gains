// lib/features/auth/widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../providers/auth_provider.dart';
import '../../../app/screens/home_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/login_screen.dart';
import 'username_setup_dialog.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String?> _checkUserStatus(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // Check if email needs verification first
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user?.providerData.first.providerId == 'password' &&
        !user!.emailVerified) {
      return 'needs_verification';
    }

    // Then check if username is needed
    if (!userDoc.exists ||
        !userDoc.data()!.containsKey('username') ||
        userDoc.data()!['username'] == null) {
      return 'needs_username';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          if (!authProvider.isAuthenticated) {
            return const LoginScreen();
          }

          return FutureBuilder<String?>(
            future: _checkUserStatus(authProvider.user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              if (snapshot.data == 'needs_verification') {
                return const EmailVerificationScreen();
              }

              if (snapshot.data == 'needs_username') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const UsernameSetupDialog(),
                  );
                });
              }

              return const HomeScreen();
            },
          );
        },
      ),
    );
  }
}

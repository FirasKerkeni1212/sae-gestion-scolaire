// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen(role: 'eleve'))),
          child: const Text('Se déconnecter'),
        ),
      ),
    );
  }
}
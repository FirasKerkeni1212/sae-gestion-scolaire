// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'auth_screen.dart';

class DashboardScreen extends StatelessWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenue, ${user.prenom} ${user.nom}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen(role: 'eleve'))),
          ),
        ],
      ),
      body: Center(child: Text('Dashboard pour ${user.role}', style: const TextStyle(fontSize: 24))),
    );
  }
}
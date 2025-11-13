// lib/screens/parent_dashboard.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart' deferred as db;
import '../models/user.dart';
import 'home_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  User? currentUser;
  List<User> children = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await db.loadLibrary();
    final users = await db.DatabaseHelper.instance.getAllUsers();
    final parent = users.firstWhere((u) => u.role == 'parent', orElse: () => users.first);
    final kids = users.where((u) => u.role == 'eleve').take(2).toList();
    setState(() {
      currentUser = parent;
      children = kids;
      loading = false;
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Parent'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Text(currentUser?.prenom[0] ?? 'P', style: const TextStyle(color: Colors.red)),
                ),
                title: Text('${currentUser?.prenom} ${currentUser?.nom}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Parent'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Mes Enfants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: children.length,
                itemBuilder: (context, i) {
                  final child = children[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(child.prenom[0])),
                      title: Text('${child.prenom} ${child.nom}'),
                      subtitle: Text('Classe : CM2 A'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dossier de ${child.prenom}')),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
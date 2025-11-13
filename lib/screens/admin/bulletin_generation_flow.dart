// lib/screens/admin/bulletin_generation_flow.dart
import 'package:flutter/material.dart';
import '../../database/database_helper.dart' deferred as db;
import 'students_by_class_screen.dart';

class BulletinGenerationFlowScreen extends StatefulWidget {
  const BulletinGenerationFlowScreen({super.key});

  @override
  State<BulletinGenerationFlowScreen> createState() => _BulletinGenerationFlowScreenState();
}

class _BulletinGenerationFlowScreenState extends State<BulletinGenerationFlowScreen> {
  List<Map<String, dynamic>> classes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    await db.loadLibrary();
    final classList = await db.DatabaseHelper.instance.getClasses();
    setState(() {
      classes = classList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une classe'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final c = classes[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFC00000),
                child: Text(c['nom'].toString().replaceAll('SAE', ''), style: const TextStyle(color: Colors.white)),
              ),
              title: Text('${c['nom']} - ${c['niveau']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentsByClassScreen(
                      classeId: c['id'] as int,
                      classeNom: c['nom'] as String,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
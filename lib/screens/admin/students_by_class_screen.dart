// lib/screens/admin/students_by_class_screen.dart
import 'package:flutter/material.dart';
import '../../database/database_helper.dart' deferred as db;
import 'bulletin_detail_screen.dart';

class StudentsByClassScreen extends StatefulWidget {
  final int classeId;
  final String classeNom;

  const StudentsByClassScreen({super.key, required this.classeId, required this.classeNom});

  @override
  State<StudentsByClassScreen> createState() => _StudentsByClassScreenState();
}

class _StudentsByClassScreenState extends State<StudentsByClassScreen> {
  List<Map<String, dynamic>> eleves = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEleves();
  }

  Future<void> _loadEleves() async {
    await db.loadLibrary();
    final allUsers = await db.DatabaseHelper.instance.getAllUsers();
    final list = allUsers.where((u) => u.role == 'eleve' && u.classeId == widget.classeId)
        .toList();

    setState(() {
      eleves = list.map((u) => {
        'id' : u.id,
        'prenom' : u.prenom,
        'nom' : u.nom,
        'identifiant' : u.identifiant,
      }).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Élèves - ${widget.classeNom}'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : eleves.isEmpty
          ? const Center(child: Text('Aucun élève dans cette classe'))
          : ListView.builder(
        itemCount: eleves.length,
        itemBuilder: (context, i) {
          final e = eleves[i];
          final nom = '${e['prenom']} ${e['nom']}';
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.school, color: Color(0xFFC00000)),
              title: Text(nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ID: ${e['identifiant']}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BulletinDetailScreen(
                      eleveId: e['id'] as int,
                      nomComplet: nom,
                      classeNom: widget.classeNom,
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
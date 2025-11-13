// lib/screens/notes/student_list_management.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../database/database_helper.dart' deferred as db;
import '../teacher_note_input.dart';

class StudentListManagementScreen extends StatefulWidget {
  final String classeNom;
  final User enseignant;

  const StudentListManagementScreen({
    super.key,
    required this.classeNom,
    required this.enseignant,
  });

  @override
  State<StudentListManagementScreen> createState() => _StudentListManagementScreenState();
}

class _StudentListManagementScreenState extends State<StudentListManagementScreen> {
  List<User> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      await db.loadLibrary();
      // Récupérer les élèves de la classe
      final allUsers = await db.DatabaseHelper.instance.getAllUsers();
      final classList = await db.DatabaseHelper.instance.getClasses();
      final classId = classList.firstWhere((c) => c['nom'] == widget.classeNom)['id'] as int;

      final filteredStudents = allUsers.where((u) =>
      u.role == 'eleve' && u.classeId == classId
      ).toList();

      setState(() {
        students = filteredStudents;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC00000),
        title: Text('Gestion Étudiants - ${widget.classeNom}'),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
          ? const Center(child: Text('Aucun étudiant dans cette classe'))
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, i) {
          final s = students[i];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('${s.prenom} ${s.nom}'),
              subtitle: Text('ID: ${s.identifiant}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherNoteInputScreen(
                    eleveId: s.id!,
                    eleveNom: '${s.prenom} ${s.nom}',
                    classeNom: widget.classeNom,
                    enseignant: widget.enseignant,
                )));
              },
            ),
          );
        },
      ),
    );
  }
}
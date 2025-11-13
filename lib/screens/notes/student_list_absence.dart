// lib/screens/notes/student_list_absence.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour formater date/heure
import '../../models/user.dart';
import '../../database/database_helper.dart';

class StudentListAbsenceScreen extends StatefulWidget {
  final String classeNom;
  final User enseignant;
  final int matiereId; // NOUVEAU : matière concernée

  const StudentListAbsenceScreen({
    super.key,
    required this.classeNom,
    required this.enseignant,
    required this.matiereId,
  });

  @override
  State<StudentListAbsenceScreen> createState() => _StudentListAbsenceScreenState();
}

class _StudentListAbsenceScreenState extends State<StudentListAbsenceScreen> {
  List<User> students = [];
  Map<int, bool> presence = {}; // true = présent, false = absent
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // Récupérer les élèves de la classe
      final allUsers = await dbHelper.getAllUsers();
      final classList = await dbHelper.getClasses();
      final classMap = {for (var c in classList) c['nom'] as String: c['id'] as int};
      final classId = classMap[widget.classeNom];

      if (classId == null) {
        throw Exception('Classe non trouvée');
      }

      final filteredStudents = allUsers.where((u) =>
      u.role == 'eleve' && u.classeId == classId).toList();

      setState(() {
        students = filteredStudents;
        for (final s in students) {
          presence[s.id!] = true; // Par défaut : présent
        }
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
        title: Text('Appel - ${widget.classeNom}'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isLoading ? null : _saveAbsences,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
          ? const Center(child: Text('Aucun étudiant dans cette classe'))
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, i) {
          final s = students[i];
          final isPresent = presence[s.id!] ?? true;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              title: Text('${s.prenom} ${s.nom}', style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('ID: ${s.identifiant}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check_circle, color: isPresent ? Colors.green : Colors.grey),
                    onPressed: () => _togglePresence(s.id!, true),
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel, color: !isPresent ? Colors.red : Colors.grey),
                    onPressed: () => _togglePresence(s.id!, false),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _togglePresence(int studentId, bool isPresent) {
    setState(() {
      presence[studentId] = isPresent;
    });
  }

  Future<void> _saveAbsences() async {
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final heure = DateFormat('HH:mm').format(now);

    final dbHelper = DatabaseHelper.instance;

    try {
      for (final student in students) {
        final isPresent = presence[student.id!] ?? true;

        await dbHelper.createAbsence(
          etudiantId: student.id!,
          isPresent: isPresent,
          date: date,
          heure: heure,
          matiereId: widget.matiereId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Absences enregistrées avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Retour à l'écran précédent
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
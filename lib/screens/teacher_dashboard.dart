// lib/screens/teacher_dashboard.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../database/database_helper.dart';
import 'notes/student_list_absence.dart';
import 'notes/student_list_management.dart';

class TeacherDashboard extends StatefulWidget {
  final User user;
  const TeacherDashboard({super.key, required this.user});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> matieres = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      final dbHelper = DatabaseHelper.instance;

      final classesList = await dbHelper.getClasses();
      final matieresList = await dbHelper.getMatieresByTeacher(widget.user.id!);

      setState(() {
        classes = classesList;
        matieres = matieresList;
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
        title: const Text('Enseignant'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC00000)))
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenue',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC00000),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.user.prenom} ${widget.user.nom}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            if (classes.isNotEmpty) ...[
              const Text('Vos classes :', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              ...classes.map((c) => Chip(
                label: Text(c['nom']),
                backgroundColor: const Color(0xFFC00000).withOpacity(0.1),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFC00000)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.user.prenom[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24, color: Color(0xFFC00000)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.user.prenom} ${widget.user.nom}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text('Enseignant', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          // ACCUEIL
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFFC00000)),
            title: const Text('Accueil'),
            onTap: () => Navigator.pop(context),
          ),

          // GESTION ABSENCES
          if (classes.isNotEmpty && matieres.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.event_busy, color: Color(0xFFC00000)),
              title: const Text('Gestion des Absences'),
              children: classes.map((classe) {
                return ListTile(
                  title: Text('Appel - ${classe['nom']}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _showMatierePicker(classe['nom'] as String);
                  },
                );
              }).toList(),
            ),

          // GESTION ÉTUDIANTS
          if (classes.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.people, color: Color(0xFFC00000)),
              title: const Text('Gestion des Étudiants'),
              children: classes.map((classe) {
                return ListTile(
                  title: Text(classe['nom']),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentListManagementScreen(
                          classeNom: classe['nom'],
                          enseignant: widget.user,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),

          const Divider(),

          // DÉCONNEXION
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion'),
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
          ),
        ],
      ),
    );
  }

  void _showMatierePicker(String classeNom) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choisir la matière pour $classeNom', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...matieres.map((m) {
                return ListTile(
                  title: Text(m['nom']),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentListAbsenceScreen(
                          classeNom: classeNom,
                          enseignant: widget.user,
                          matiereId: m['id'] as int,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
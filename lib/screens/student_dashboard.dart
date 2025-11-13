// lib/screens/student_dashboard.dart
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'home_screen.dart';
import 'notes/student_notes_dashboard.dart';
import 'student/absence_screen.dart';

class StudentDashboard extends StatefulWidget {
  final String prenom;
  final String nom;
  final String classe;
  final String identifiant;
  final int id;

  const StudentDashboard({
    super.key,
    required this.prenom,
    required this.nom,
    required this.classe,
    required this.identifiant,
    required this.id,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  int _notificationCount = 0;
  String? _bulletinPath;

  @override
  void initState() {
    super.initState();
    _checkForBulletin();
  }

  // Vérifie si le bulletin PDF existe
  Future<void> _checkForBulletin() async {
    final dir = await getApplicationDocumentsDirectory();
    final nomComplet = '${widget.prenom} ${widget.nom}';
    final file = File('${dir.path}/bulletin_$nomComplet.pdf');

    if (await file.exists()) {
      setState(() {
        _notificationCount = 1;
        _bulletinPath = file.path;
      });
    }
  }

  // Liste des pages
  List<Widget> get _pages {
    return [
      const AccueilTab(),
      const EmploiTab(),
      AbsenceScreen(
        eleveNom: '${widget.prenom} ${widget.nom}',
        eleveId: widget.id,
      ),
      const ExamensTab(),
      const EvaluationTab(),
      StudentNotesDashboard(
        eleveId: widget.id,
        eleveNom: '${widget.prenom} ${widget.nom}',
      ),
      const ReclamationTab(),
      const ChangePasswordTab(),
      const DocumentsStageTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Étudiant • ${widget.classe}'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // CLOCHE DE NOTIFICATION
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: badges.Badge(
              showBadge: _notificationCount > 0,
              badgeContent: Text(
                _notificationCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(6),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications, size: 28),
                onPressed: () async {
                  if (_bulletinPath != null) {
                    await OpenFile.open(_bulletinPath!);
                    setState(() {
                      _notificationCount = 0; // Badge disparaît
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aucun bulletin disponible.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          // DÉCONNEXION
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  // DRAWER PERSONNALISÉ
  Drawer _buildDrawer() {
    final menuItems = [
      {'title': 'Accueil', 'icon': Icons.home},
      {'title': 'Emploi du temps', 'icon': Icons.schedule},
      {'title': 'Absence', 'icon': Icons.event_busy},
      {'title': 'EXAMENS', 'icon': Icons.assignment},
      {'title': 'Évaluation', 'icon': Icons.rate_review},
      {'title': 'Résultat', 'icon': Icons.bar_chart},
      {'title': 'Réclamation', 'icon': Icons.feedback},
      {'title': 'Changer mot de passe', 'icon': Icons.lock},
      {'title': 'Documents de stages', 'icon': Icons.folder},
    ];

    final footerItems = [
      {'title': 'Historique de rang', 'icon': Icons.history},
      {'title': 'Crédits', 'icon': Icons.info},
    ];

    return Drawer(
      child: Container(
        color: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // HEADER
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFC00000)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.prenom.isNotEmpty ? widget.prenom[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 24, color: Color(0xFFC00000)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.prenom} ${widget.nom}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'SAE • ${widget.classe}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // MENU PRINCIPAL
            ...menuItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _selectedIndex == index;
              return ListTile(
                leading: Icon(
                  item['icon'] as IconData,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                title: Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                tileColor: isSelected ? const Color(0xFFC00000) : null,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              );
            }),

            const Divider(color: Colors.white24),

            // FOOTER
            ...footerItems.asMap().entries.map((entry) {
              final index = menuItems.length + entry.key;
              final item = entry.value;
              final isSelected = _selectedIndex == index;
              return ListTile(
                leading: Icon(
                  item['icon'] as IconData,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                title: Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                tileColor: isSelected ? const Color(0xFFC00000) : null,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// PAGES VIDES (À REMPLIR PLUS TARD)
class AccueilTab extends StatelessWidget {
  const AccueilTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Accueil', style: TextStyle(fontSize: 24)));
}

class EmploiTab extends StatelessWidget {
  const EmploiTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Emploi du temps', style: TextStyle(fontSize: 24)));
}

class ExamensTab extends StatelessWidget {
  const ExamensTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('EXAMENS', style: TextStyle(fontSize: 24)));
}

class EvaluationTab extends StatelessWidget {
  const EvaluationTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Évaluation', style: TextStyle(fontSize: 24)));
}

class ReclamationTab extends StatelessWidget {
  const ReclamationTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Réclamation', style: TextStyle(fontSize: 24)));
}

class ChangePasswordTab extends StatelessWidget {
  const ChangePasswordTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Changer mot de passe', style: TextStyle(fontSize: 24)));
}

class DocumentsStageTab extends StatelessWidget {
  const DocumentsStageTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Documents de stages', style: TextStyle(fontSize: 24)));
}
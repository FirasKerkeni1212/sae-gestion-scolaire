// lib/screens/student/student_result_tab.dart
import 'package:flutter/material.dart';
import '../notes/student_evolution_chart.dart'; // IMPORT CORRECT
import '../../database/database_helper.dart';

class StudentResultTab extends StatefulWidget {
  final int studentId;
  final String studentName;

  const StudentResultTab({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentResultTab> createState() => _StudentResultTabState();
}

class _StudentResultTabState extends State<StudentResultTab> with AutomaticKeepAliveClientMixin {
  List<String> matieres = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMatieres();
  }

  Future<void> _loadMatieres() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final notes = await dbHelper.getNotesByEleve(widget.studentId);
      final uniqueMatieres = notes
          .map((n) => n['matiere_nom'] as String)
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          matieres = uniqueMatieres;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFC00000)))
        : matieres.isEmpty
        ? _buildEmptyState()
        : _buildCharts();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Aucune note enregistrée', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Évolution des notes',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC00000)),
        ),
        const SizedBox(height: 16),
        ...matieres.map((matiere) => Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: StudentEvolutionChart(
            studentId: widget.studentId,
            matiereNom: matiere,
          ),
        )),
      ],
    );
  }
}
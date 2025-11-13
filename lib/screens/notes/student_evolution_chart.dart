// lib/screens/notes/student_evolution_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../database/database_helper.dart' deferred as db;

class StudentEvolutionChart extends StatefulWidget {
  final int studentId;
  final String matiereNom;

  const StudentEvolutionChart({
    super.key,
    required this.studentId,
    required this.matiereNom,
  });

  @override
  State<StudentEvolutionChart> createState() => _StudentEvolutionChartState();
}

class _StudentEvolutionChartState extends State<StudentEvolutionChart> {
  List<Map<String, dynamic>> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      await db.loadLibrary();
      final dbHelper = db.DatabaseHelper.instance;

      // Trouver l'ID de la matière
      final matieres = await dbHelper.getMatieres();
      final matiereMap = matieres.firstWhere(
            (m) => m['nom'] == widget.matiereNom,
        orElse: () => <String, dynamic>{},
      );

      if (matiereMap.isEmpty) {
        setState(() {
          notes = [];
          isLoading = false;
        });
        return;
      }

      final matiereId = matiereMap['id'] as int;

      // CORRIGÉ : Convertir en liste modifiable
      final rawNotes = List<Map<String, dynamic>>.from(
          await dbHelper.getNotesByEtudiantAndMatiere(widget.studentId, matiereId)
      );

      // Trier par date
      rawNotes.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

      setState(() {
        notes = rawNotes;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur chargement notes: $e");
      setState(() {
        notes = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildCard(child: const CircularProgressIndicator());
    }

    if (notes.isEmpty) {
      return _buildCard(child: const Text('Aucune note', style: TextStyle(color: Colors.grey)));
    }

    final spots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final valeur = (note['valeur'] as num).toDouble();
      final type = note['type_note'] as String;

      spots.add(FlSpot(i.toDouble(), valeur));
      labels.add(type);
    }

    return _buildCard(
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < labels.length) {
                      return Text(labels[index], style: const TextStyle(fontSize: 10));
                    }
                    return const Text('');
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            minX: 0,
            maxX: (spots.length - 1).toDouble(),
            minY: 0,
            maxY: 20,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                color: const Color(0xFFC00000),
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFC00000).withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.matiereNom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
// lib/screens/notes/student_notes_dashboard.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart' deferred as db;
import 'student_evolution_chart.dart';

class StudentNotesDashboard extends StatefulWidget {
  final int eleveId;
  final String eleveNom;

  const StudentNotesDashboard({
    super.key,
    required this.eleveId,
    required this.eleveNom,
  });

  @override
  State<StudentNotesDashboard> createState() => _StudentNotesDashboardState();
}

class _StudentNotesDashboardState extends State<StudentNotesDashboard> {
  List<Map<String, dynamic>> notes = [];
  Map<String, double?> moyennes = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await db.loadLibrary();
    final dbHelper = db.DatabaseHelper.instance;

    final noteList = await dbHelper.getNotesByEleve(widget.eleveId);
    final matieres = await dbHelper.getMatieres();

    final Map<String, double?> tempMoyennes = {};

    for (final matiere in matieres) {
      final matiereId = matiere['id'] as int;
      final matiereNom = matiere['nom'] as String;

      final moyenneRaw = await dbHelper.getMoyennePondereeDynamique(widget.eleveId, matiereId);
      final moyenne = moyenneRaw != null ? moyenneRaw.toDouble() : null;

      tempMoyennes[matiereNom] = moyenne;
    }

    setState(() {
      notes = noteList;
      moyennes = tempMoyennes;
      isLoading = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupByMatiere() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final note in notes) {
      final matiere = note['matiere_nom'] as String;
      grouped.putIfAbsent(matiere, () => []);
      grouped[matiere]!.add(note);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC00000))),
      );
    }

    final groupedNotes = _groupByMatiere();
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Étudiant - ${widget.eleveNom}'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dernières notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (groupedNotes.isEmpty)
                _buildEmptyCard('Aucune note enregistrée')
              else
                ...groupedNotes.entries.map((entry) {
                  final matiere = entry.key;
                  final notesMatiere = entry.value;
                  final moyenne = moyennes[matiere];

                  final derniereNote = notesMatiere.reduce((a, b) {
                    return DateTime.parse(a['date']).isAfter(DateTime.parse(b['date'])) ? a : b;
                  });

                  final Map<String, Map<String, dynamic>> latestByType = {};
                  for (final n in notesMatiere) {
                    final type = n['type_note'] as String;
                    final date = DateTime.parse(n['date']);
                    if (!latestByType.containsKey(type) ||
                        date.isAfter(DateTime.parse(latestByType[type]!['date']))) {
                      latestByType[type] = n;
                    }
                  }

                  return _buildNoteCard(
                    matiere: matiere,
                    derniereNote: derniereNote,
                    latestByType: latestByType,
                    moyenne: moyenne,
                    dateFormat: dateFormat,
                  );
                }),

              const SizedBox(height: 32),
              const Text('Évolution des notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (groupedNotes.isEmpty)
                _buildEmptyCard('Graphique en cours de développement')
              else
                ...groupedNotes.keys.map((matiere) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: StudentEvolutionChart(studentId: widget.eleveId, matiereNom: matiere),
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard({
    required String matiere,
    required Map<String, dynamic> derniereNote,
    required Map<String, Map<String, dynamic>> latestByType,
    required double? moyenne,
    required DateFormat dateFormat,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(matiere, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                Text('Dernière : ${dateFormat.format(DateTime.parse(derniereNote['date']))}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChip('CC', latestByType['CC']?['valeur'], Colors.blue[100]!),
                _buildChip('DS', latestByType['DS']?['valeur'], Colors.green[100]!),
                _buildChip('Examen', latestByType['Examen']?['valeur'], Colors.red[100]!),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                moyenne != null ? 'Moyenne ${moyenne.toStringAsFixed(1)}' : 'Moyenne —',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: moyenne != null && moyenne < 10 ? Colors.red : const Color(0xFFC00000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, dynamic value, Color bg) {
    final display = value != null ? (value as num).toStringAsFixed(1) : '-';
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: bg,
          child: Text(display, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
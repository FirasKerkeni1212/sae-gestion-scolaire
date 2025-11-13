// lib/screens/admin/bulletin_detail_screen.dart
import 'package:flutter/material.dart';
import '../../database/database_helper.dart' deferred as db;
import '../../services/pdf_service.dart';

class BulletinDetailScreen extends StatefulWidget {
  final int eleveId;
  final String nomComplet;
  final String classeNom;

  const BulletinDetailScreen({
    super.key,
    required this.eleveId,
    required this.nomComplet,
    required this.classeNom,
  });

  @override
  State<BulletinDetailScreen> createState() => _BulletinDetailScreenState();
}

class _BulletinDetailScreenState extends State<BulletinDetailScreen> {
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
    final n = await dbHelper.getNotesByEleve(widget.eleveId);
    final matieres = await dbHelper.getMatieres();
    final Map<String, double?> m = {};
    for (var mat in matieres) {
      final avg = await dbHelper.getMoyennePondereeDynamique(widget.eleveId, mat['id'] as int);
      m[mat['nom'] as String] = avg;
    }
    setState(() {
      notes = n;
      moyennes = m;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nomComplet),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.school, color: Color(0xFFC00000)),
                title: Text('Classe: ${widget.classeNom}'),
                subtitle: Text('Élève: ${widget.nomComplet}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, i) {
                  final n = notes[i];
                  return Card(
                    child: ListTile(
                      title: Text(n['matiere_nom']),
                      subtitle: Text('${n['type_note']}: ${n['valeur']}'),
                      trailing: Text('Moy: ${moyennes[n['matiere_nom']]?.toStringAsFixed(1) ?? '-'}'),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC00000),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Générer Bulletin PDF', style: TextStyle(fontSize: 16)),
              onPressed: () async {
                await PdfService.generateAndShareBulletin(
                  etudiantId: widget.eleveId,
                  nomComplet: widget.nomComplet,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bulletin généré !')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
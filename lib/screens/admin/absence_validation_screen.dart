// lib/screens/admin/absence_validation_screen.dart
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../database/database_helper.dart';

class AbsenceValidationScreen extends StatefulWidget {
  @override
  _AbsenceValidationScreenState createState() => _AbsenceValidationScreenState();
}

class _AbsenceValidationScreenState extends State<AbsenceValidationScreen> {
  List<Map<String, dynamic>> _absencesEnAttente = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAbsences();
  }

  Future<void> _loadAbsences() async {
    final db = DatabaseHelper.instance;
    final result = await db.database;
    final list = await result.rawQuery('''
      SELECT 
        a.id,
        a.date,
        a.heure,
        a.motif,
        a.justificatif_path,
        a.statut,
        u.prenom,
        u.nom,
        m.nom AS matiere_nom
      FROM absences a
      JOIN users u ON a.etudiant_id = u.id
      JOIN matieres m ON a.matiere_id = m.id
      WHERE a.statut = 'en_attente'
      ORDER BY a.date DESC, a.heure DESC
    ''');

    setState(() {
      _absencesEnAttente = list;
      _isLoading = false;
    });
  }

  Future<void> _validate(int id, bool approved) async {
    await DatabaseHelper.instance.validateJustification(id, approved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approved ? 'Justification acceptée' : 'Justification rejetée'),
        backgroundColor: approved ? Colors.green : Colors.red,
      ),
    );
    _loadAbsences(); // Rafraîchir
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Validation des justifications')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _absencesEnAttente.isEmpty
          ? Center(child: Text('Aucune justification en attente'))
          : ListView.builder(
        itemCount: _absencesEnAttente.length,
        itemBuilder: (ctx, i) {
          final a = _absencesEnAttente[i];
          return Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${a['prenom']} ${a['nom']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Matière : ${a['matiere_nom']}'),
                  Text('Date : ${a['date']} à ${a['heure']}'),
                  SizedBox(height: 8),
                  Text('Motif : ${a['motif'] ?? 'Non renseigné'}'),
                  if (a['justificatif_path'] != null) ...[
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.attach_file),
                      label: Text('Voir justificatif'),
                      onPressed: () => OpenFile.open(a['justificatif_path']),
                    ),
                  ],
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => _validate(a['id'], false),
                        child: Text('Rejeter'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _validate(a['id'], true),
                        child: Text('Accepter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
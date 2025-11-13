// lib/screens/notes/report_card.dart
import 'package:flutter/material.dart';

class ReportCardScreen extends StatelessWidget {
  final int? eleveId;
  final String? eleveNom;
  const ReportCardScreen({
    super.key,
  this.eleveId,
  this.eleveNom});

  final List<Map<String, dynamic>> bulletin = const [
    {'matiere': 'Électricité Industrielle', 'notes': [15, 17, 14], 'coef': 3},
    {'matiere': 'Automatismes', 'notes': [16, 18, 15], 'coef': 2},
    {'matiere': 'Programmation Automates', 'notes': [14, 16, 13], 'coef': 3},
    {'matiere': 'Réseaux Industriels', 'notes': [17, 15, 16], 'coef': 2},
    {'matiere': 'Projets SAE', 'notes': [18, 19, 17], 'coef': 4},
  ];

  double _calculateAverage(List<int> notes, int coef) {
    final sum = notes.reduce((a,b) => a + b);
    final average = sum / notes.length;
    return average;
  }

  @override
  Widget build(BuildContext context) {
    double totalPoints = 0;
    int totalCoef = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulletin scolaire'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Bulletin - Trimestre 1',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Tableau
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade400, width: 1),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                  },
                  children: [
                    // En-tête
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFC00000)),
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('Matière', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Moyenne', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Coef', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ],
                    ),

                    // Lignes
                    ...bulletin.map((item) {
                      final List<int> notes = item['notes'] as List<int>;
                      final int coef = item['coef'] as int;
                      final double avg = _calculateAverage(notes,coef);

                      totalPoints += avg * coef;
                      totalCoef += coef;

                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(item['matiere'])),
                          Padding(padding: const EdgeInsets.all(8), child: Text(item['notes'].join(', '))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(avg.toStringAsFixed(1))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(item['coef'].toString())),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Moyenne générale
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Moyenne générale : ${(totalPoints / totalCoef).toStringAsFixed(2)} / 20',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),

            const SizedBox(height: 16),

            // Export PDF
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bulletin exporté en PDF !')),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text('Exporter en PDF', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC00000),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
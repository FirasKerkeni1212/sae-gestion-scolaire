// lib/screens/student/absence_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../justify_absence_screen.dart'; // ✅ IMPORT DU NOUVEL ÉCRAN

class AbsenceScreen extends StatefulWidget {
  final String eleveNom;
  final int eleveId;

  const AbsenceScreen({
    super.key,
    required this.eleveNom,
    required this.eleveId,
  });

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  List<Map<String, dynamic>> absences = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAbsences();
  }

  Future<void> _loadAbsences() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final rawAbsences = await dbHelper.getAbsencesByEleve(widget.eleveId);

      rawAbsences.sort((a, b) {
        final dateA = '${a['date'] ?? ''} ${a['heure'] ?? ''}';
        final dateB = '${b['date'] ?? ''} ${b['heure'] ?? ''}';
        return dateB.compareTo(dateA);
      });

      setState(() {
        absences = rawAbsences;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => isLoading = false);
    }
  }

  // ✅ NOUVELLE MÉTHODE : Ouvrir l'écran de justification
  Future<void> _openJustifyScreen(Map<String, dynamic> absence) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JustifyAbsenceScreen(absence: absence),
      ),
    );

    // Si la justification a été envoyée avec succès, recharger la liste
    if (result == true) {
      _loadAbsences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
        title: Text('Absences - ${widget.eleveNom}'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC00000)))
          : absences.isEmpty
          ? _buildEmptyState()
          : _buildAbsenceList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucune absence',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Élève exemplaire !',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTHODE POUR OBTENIR LE BADGE DE STATUT
  Widget _getStatusBadge(String? statut) {
    final status = statut ?? 'non_justifiee';

    switch (status) {
      case 'justifiee':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
              const SizedBox(width: 4),
              Text(
                'Justifiée',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 'en_attente':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty, size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text(
                'En attente',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, size: 14, color: Colors.red.shade700),
              const SizedBox(width: 4),
              Text(
                'Non justifiée',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildAbsenceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: absences.length,
      itemBuilder: (context, index) {
        final a = absences[index];
        final isPresent = a['is_present'] == 1;
        final dateStr = a['date'] as String?;
        final heureStr = a['heure'] as String?;
        final matiere = a['matiere_nom'] as String?;
        final statut = a['statut'] as String?;

        String formattedDate = 'Date inconnue';
        if (dateStr != null) {
          try {
            formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
          } catch (e) {
            formattedDate = dateStr;
          }
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isPresent ? Colors.green : Colors.red,
                      child: Icon(
                        isPresent ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            matiere ?? 'Matière inconnue',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$formattedDate à ${heureStr ?? 'Heure inconnue'}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          _getStatusBadge(statut),
                        ],
                      ),
                    ),
                    // ✅ ICÔNE D'ALERTE
                    if (!isPresent && statut == 'non_justifiee')
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  ],
                ),

                // ✅ BOUTON JUSTIFIER (uniquement si absent et non justifié)
                if (!isPresent && statut != 'justifiee') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: statut == 'en_attente'
                          ? null
                          : () => _openJustifyScreen(a),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statut == 'en_attente'
                            ? Colors.grey
                            : const Color(0xFFC00000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        statut == 'en_attente'
                            ? Icons.hourglass_empty
                            : Icons.description,
                        size: 20,
                      ),
                      label: Text(
                        statut == 'en_attente'
                            ? 'Justification en cours...'
                            : 'Justifier cette absence',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
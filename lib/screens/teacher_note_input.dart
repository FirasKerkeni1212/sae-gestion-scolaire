// lib/screens/notes/teacher_note_input.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../database/database_helper.dart';
import 'notes/student_list_absence.dart';
import 'notes/student_list_management.dart';

class TeacherNoteInputScreen extends StatefulWidget {
  final int eleveId;
  final String eleveNom;
  final String classeNom;
  final User enseignant;

  const TeacherNoteInputScreen({
    super.key,
    required this.eleveId,
    required this.eleveNom,
    required this.classeNom,
    required this.enseignant,
  });

  @override
  State<TeacherNoteInputScreen> createState() => _TeacherNoteInputScreenState();
}

class _TeacherNoteInputScreenState extends State<TeacherNoteInputScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _types = ['CC', 'DS', 'Examen', 'Projet'];
  int? _matiereId;
  String? _matiereNom;
  List<Map<String, dynamic>> matieres = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMatieresAndNotes();
  }

  Future<void> _loadMatieresAndNotes() async {
    final db = DatabaseHelper.instance;

    try {
      // Charger les matières
      final list = await db.getMatieresByTeacher(widget.enseignant.id!);
      final notes = await db.getNotesByEtudiantAndClasse(
        widget.eleveId,
        widget.classeNom,
      );

      setState(() {
        matieres = list;
        if (list.isNotEmpty) {
          _matiereId = list[0]['id'] as int;
          _matiereNom = list[0]['nom'] as String;
        }
        _isLoading = false;
      });

      // Initialiser les contrôleurs
      for (var type in _types) {
        _controllers[type] = TextEditingController();
      }

      // Pré-remplir si note existe
      for (var note in notes) {
        final type = note['type_note'] as String;
        final valeur = note['valeur']?.toString() ?? '';
        if (_controllers.containsKey(type)) {
          _controllers[type]!.text = valeur;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
        title: const Text('Saisie de Note'),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC00000)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Infos élève + classe
            Card(
              color: const Color(0xFFC00000).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eleveNom,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Classe: ${widget.classeNom}',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sélection matière
            DropdownButtonFormField<int>(
              value: _matiereId,
              decoration: InputDecoration(
                labelText: 'Matière',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: matieres
                  .map((m) => DropdownMenuItem(
                value: m['id'] as int,
                child: Text(m['nom']),
              ))
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (v) {
                setState(() {
                  _matiereId = v;
                  _matiereNom = matieres.firstWhere((m) => m['id'] == v)['nom'];
                });
                // Recharger les notes pour la nouvelle matière
                _loadNotesForMatiere(v!);
              },
            ),
            const SizedBox(height: 24),

            // Tous les types de notes
            ..._types.map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        type,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _controllers[type],
                        enabled: !_isSaving,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '-',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = double.tryParse(v);
                          if (n == null || n < 0 || n > 20) return '0 à 20';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 32),

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_matiereId == null || _isSaving) ? null : _saveAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC00000),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving
                    ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Enregistrement...', style: TextStyle(color: Colors.white)),
                  ],
                )
                    : const Text(
                  'Enregistrer toutes les notes',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Charger les notes pour une matière donnée
  Future<void> _loadNotesForMatiere(int matiereId) async {
    final db = DatabaseHelper.instance;
    final notes = await db.getNotesByEtudiantAndMatiere(widget.eleveId, matiereId);

    // Réinitialiser
    for (var type in _types) {
      _controllers[type]!.clear();
    }

    // Remplir
    for (var note in notes) {
      final type = note['type_note'] as String;
      final valeur = note['valeur']?.toString() ?? '';
      if (_controllers.containsKey(type)) {
        _controllers[type]!.text = valeur;
      }
    }
  }

  // Sauvegarder toutes les notes
  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    final db = DatabaseHelper.instance;
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      for (var type in _types) {
        final ctrl = _controllers[type]!;
        final value = double.tryParse(ctrl.text);
        if (value != null && value >= 0 && value <= 20) {
          await db.createNote(
            etudiantId: widget.eleveId,
            matiereId: _matiereId!,
            typeNote: type,
            valeur: value,
            date: date,
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notes enregistrées !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Drawer (inchangé)
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
                    widget.enseignant.prenom[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24, color: Color(0xFFC00000)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.enseignant.prenom} ${widget.enseignant.nom}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text('Enseignant', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_busy, color: Color(0xFFC00000)),
            title: const Text('Gestion des Absences'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentListAbsenceScreen(
                    classeNom: widget.classeNom,
                    enseignant: widget.enseignant,
                    matiereId: _matiereId ?? matieres.first['id'] as int,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Color(0xFFC00000)),
            title: const Text('Gestion des Étudiants'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentListManagementScreen(
                    classeNom: widget.classeNom,
                    enseignant: widget.enseignant,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion'),
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }
}
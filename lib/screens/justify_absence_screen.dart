// lib/screens/justify_absence_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';

class JustifyAbsenceScreen extends StatefulWidget {
  final Map<String, dynamic> absence;

  const JustifyAbsenceScreen({
    super.key,
    required this.absence,
  });

  @override
  State<JustifyAbsenceScreen> createState() => _JustifyAbsenceScreenState();
}

class _JustifyAbsenceScreenState extends State<JustifyAbsenceScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedMotif;
  final commentaireCtrl = TextEditingController();
  File? selectedFile;
  String? fileName;
  bool isSubmitting = false;

  final List<String> motifs = [
    'Maladie',
    'Rendez-vous médical',
    'Problème familial',
    'Événement exceptionnel',
    'Autre',
  ];

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
          fileName = result.files.single.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Fichier sélectionné : $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la sélection : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _saveFile(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final justificatifsDir = Directory('${appDir.path}/justificatifs');

      if (!await justificatifsDir.exists()) {
        await justificatifsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final newPath = '${justificatifsDir.path}/justif_${widget.absence['id']}_$timestamp$extension';

      await file.copy(newPath);
      return newPath;
    } catch (e) {
      print('Erreur sauvegarde fichier : $e');
      return null;
    }
  }

  Future<void> _submitJustification() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedMotif == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Veuillez sélectionner un motif'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      String? savedPath;
      if (selectedFile != null) {
        savedPath = await _saveFile(selectedFile!);
        if (savedPath == null) {
          throw Exception('Impossible de sauvegarder le fichier');
        }
      }

      final motifComplet = selectedMotif == 'Autre' && commentaireCtrl.text.isNotEmpty
          ? '${selectedMotif!} : ${commentaireCtrl.text}'
          : selectedMotif!;

      await DatabaseHelper.instance.justifyAbsence(
        absenceId: widget.absence['id'],
        motif: motifComplet,
        justificatifPath: savedPath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Justification envoyée avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true); // Retour avec succès
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    commentaireCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text('Justifier mon absence'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📅 Carte d'information sur l'absence
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFC00000).withOpacity(0.1),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC00000),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event_busy,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vous étiez absent(e) le :',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.absence['date']} à ${widget.absence['heure']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC00000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.book, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Matière : ${widget.absence['matiere_nom']}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 📝 Sélection du motif
              const Text(
                'Motif de l\'absence *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC00000),
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedMotif,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.question_answer, color: Color(0xFFC00000)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Sélectionnez un motif',
                ),
                items: motifs.map((motif) {
                  return DropdownMenuItem(
                    value: motif,
                    child: Text(motif),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedMotif = value);
                },
                validator: (value) => value == null ? 'Champ requis' : null,
              ),

              const SizedBox(height: 20),

              // 💬 Commentaire additionnel
              const Text(
                'Commentaire (optionnel)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC00000),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: commentaireCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.comment, color: Color(0xFFC00000)),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Ajoutez des détails si nécessaire...',
                ),
              ),

              const SizedBox(height: 30),

              // 📎 Déposer un justificatif PDF
              const Text(
                'Justificatif (PDF) *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC00000),
                ),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedFile != null ? Colors.green : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        selectedFile != null ? Icons.check_circle : Icons.upload_file,
                        size: 50,
                        color: selectedFile != null ? Colors.green : const Color(0xFFC00000),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selectedFile != null
                            ? '✅ $fileName'
                            : '📎 Cliquez pour choisir un fichier PDF',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: selectedFile != null ? Colors.green : Colors.grey.shade700,
                        ),
                      ),
                      if (selectedFile != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedFile = null;
                              fileName = null;
                            });
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Retirer'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ✅ Bouton d'envoi
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitJustification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC00000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Envoyer la justification',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ℹ️ Information
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Votre justification sera examinée par l\'administration.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
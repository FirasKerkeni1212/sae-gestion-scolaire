// lib/utils/note_calculator.dart
class NoteCalculator {
  /// Calcule la moyenne d'une matière selon les règles SAE
  static double calculerMoyenneMatiere(List<Map<String, dynamic>> notes) {
    // Cas spécial : Projet = 100%
    final projet = notes.firstWhere(
          (n) => n['type_note'] == 'Projet',
      orElse: () => <String, dynamic>{},
    );
    if (projet.isNotEmpty) {
      return (projet['valeur'] as num).toDouble();
    }

    // Récupérer les valeurs
    final cc = _getValeur(notes, 'CC');
    final ds = _getValeur(notes, 'DS');
    final examen = _getValeur(notes, 'Examen');

    // Cas 1 : CC + Examen → 0.4 CC + 0.6 Examen
    if (cc != null && examen != null && ds == null) {
      return (cc * 0.4) + (examen * 0.6);
    }

    // Cas 2 : DS + Examen → 0.2 DS + 0.8 Examen
    if (ds != null && examen != null && cc == null) {
      return (ds * 0.2) + (examen * 0.8);
    }

    // Cas 3 : CC + DS + Examen → 0.3 CC + 0.2 DS + 0.5 Examen
    if (cc != null && ds != null && examen != null) {
      return (cc * 0.3) + (ds * 0.2) + (examen * 0.5);
    }

    // Sinon : moyenne des notes existantes
    final valeurs = notes
        .map((n) => (n['valeur'] as num).toDouble())
        .where((v) => v >= 0)
        .toList();
    return valeurs.isEmpty ? 0.0 : valeurs.reduce((a, b) => a + b) / valeurs.length;
  }

  /// Retourne la valeur d'une note ou null
  static double? _getValeur(List<Map<String, dynamic>> notes, String type) {
    final note = notes.firstWhere(
          (n) => n['type_note'] == type,
      orElse: () => <String, dynamic>{},
    );
    if (note.isEmpty) return null;
    final valeur = note['valeur'];
    return valeur is num ? valeur.toDouble() : null;
  }
}
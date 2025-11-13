// lib/database/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('edufollow.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // === CRÉATION DES TABLES ===
  Future<void> _createDB(Database db, int version) async {
    print('Création des tables (version $version)');

    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        niveau TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identifiant TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        role TEXT NOT NULL,
        classe_id INTEGER,
        FOREIGN KEY (classe_id) REFERENCES classes (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE enseignants_classes (
        enseignant_id INTEGER,
        classe_id INTEGER,
        PRIMARY KEY (enseignant_id, classe_id),
        FOREIGN KEY (enseignant_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (classe_id) REFERENCES classes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE matieres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        etudiant_id INTEGER NOT NULL,
        matiere_id INTEGER NOT NULL,
        type_note TEXT NOT NULL CHECK(type_note IN ('CC', 'DS', 'Examen', 'Projet')),
        valeur REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (etudiant_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (matiere_id) REFERENCES matieres (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_notes_unique 
      ON notes(etudiant_id, matiere_id, type_note)
    ''');

    await db.execute('''
      CREATE TABLE parent_eleve (
        parent_id INTEGER NOT NULL,
        eleve_id INTEGER NOT NULL,
        PRIMARY KEY (parent_id, eleve_id),
        FOREIGN KEY (parent_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (eleve_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE enseignants_matieres (
        enseignant_id INTEGER,
        matiere_id INTEGER,
        PRIMARY KEY (enseignant_id, matiere_id),
        FOREIGN KEY (enseignant_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (matiere_id) REFERENCES matieres (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE absences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        etudiant_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        heure TEXT NOT NULL,
        is_present INTEGER NOT NULL CHECK(is_present IN (0, 1)),
        matiere_id INTEGER NOT NULL,
        motif TEXT,
        justificatif_path TEXT,
        statut TEXT DEFAULT 'non_justifiee' CHECK(statut IN ('non_justifiee', 'en_attente', 'justifiee')),
        date_justification TEXT,
        FOREIGN KEY (etudiant_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (matiere_id) REFERENCES matieres (id) ON DELETE CASCADE
      )
    ''');

    print('Tables créées avec succès !');
  }

  // === MIGRATION ===
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE absences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          etudiant_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          heure TEXT NOT NULL,
          is_present INTEGER NOT NULL CHECK(is_present IN (0, 1)),
          matiere_id INTEGER NOT NULL,
          FOREIGN KEY (etudiant_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (matiere_id) REFERENCES matieres (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE absences ADD COLUMN motif TEXT');
      await db.execute('ALTER TABLE absences ADD COLUMN justificatif_path TEXT');
      await db.execute("ALTER TABLE absences ADD COLUMN statut TEXT DEFAULT 'non_justifiee'");
      await db.execute('ALTER TABLE absences ADD COLUMN date_justification TEXT');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_notes_unique 
        ON notes(etudiant_id, matiere_id, type_note)
      ''');
    }
  }

  // === NOTES ===
  Future<void> createNote({
    required int etudiantId,
    required int matiereId,
    required String typeNote,
    required double valeur,
    required String date,
  }) async {
    final db = await database;
    await db.rawInsert('''
      INSERT INTO notes (etudiant_id, matiere_id, type_note, valeur, date)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(etudiant_id, matiere_id, type_note) 
      DO UPDATE SET valeur = excluded.valeur, date = excluded.date
    ''', [etudiantId, matiereId, typeNote, valeur, date]);
  }

  Future<List<Map<String, dynamic>>> getNotesByEleve(int eleveId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT n.*, m.nom AS matiere_nom
      FROM notes n
      JOIN matieres m ON n.matiere_id = m.id
      WHERE n.etudiant_id = ?
      ORDER BY n.date DESC
    ''', [eleveId]);
  }

  Future<List<Map<String, dynamic>>> getNotesByEtudiantAndClasse(
      int etudiantId,
      String classeNom,
      ) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT n.*, m.nom AS matiere_nom 
      FROM notes n
      JOIN matieres m ON n.matiere_id = m.id
      JOIN users u ON n.etudiant_id = u.id
      JOIN classes c ON u.classe_id = c.id
      WHERE n.etudiant_id = ? AND c.nom = ?
      ORDER BY n.date DESC
    ''', [etudiantId, classeNom]);
  }

  Future<List<Map<String, dynamic>>> getNotesByEtudiantAndMatiere(
      int etudiantId,
      int matiereId,
      ) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM notes 
      WHERE etudiant_id = ? AND matiere_id = ?
    ''', [etudiantId, matiereId]);
  }

  // === MOYENNE PONDÉRÉE DYNAMIQUE (4 CAS) ===
  Future<double?> getMoyennePondereeDynamique(int etudiantId, int matiereId) async {
    final db = await database;

    final notes = await db.query(
      'notes',
      where: 'etudiant_id = ? AND matiere_id = ?',
      whereArgs: [etudiantId, matiereId],
    );

    double ccSum = 0, dsSum = 0, examenSum = 0;
    int ccCount = 0, dsCount = 0, examenCount = 0;

    for (var note in notes) {
      final type = note['type_note'] as String;
      final valeur = (note['valeur'] as num).toDouble();

      switch (type) {
        case 'CC':
          ccSum += valeur;
          ccCount++;
          break;
        case 'DS':
          dsSum += valeur;
          dsCount++;
          break;
        case 'Examen':
          examenSum += valeur;
          examenCount++;
          break;
      }
    }

    final avgCC = ccCount > 0 ? ccSum / ccCount : 0.0;
    final avgDS = dsCount > 0 ? dsSum / dsCount : 0.0;
    final avgExamen = examenCount > 0 ? examenSum / examenCount : 0.0;

    final hasCC = ccCount > 0;
    final hasDS = dsCount > 0;
    final hasExamen = examenCount > 0;

    if (hasCC && hasDS && hasExamen) {
      return (avgCC * 0.3) + (avgDS * 0.2) + (avgExamen * 0.5);
    }
    if (hasCC && hasExamen && !hasDS) {
      return (avgCC * 0.4) + (avgExamen * 0.6);
    }
    if (hasDS && hasExamen && !hasCC) {
      return (avgDS * 0.2) + (avgExamen * 0.8);
    }
    if (hasExamen && !hasCC && !hasDS) {
      return avgExamen;
    }

    return null;
  }

  // === ABSENCES ===
  Future<void> createAbsence({
    required int etudiantId,
    required bool isPresent,
    required String date,
    required String heure,
    required int matiereId,
  }) async {
    final db = await database;
    await db.insert('absences', {
      'etudiant_id': etudiantId,
      'date': date,
      'heure': heure,
      'is_present': isPresent ? 1 : 0,
      'matiere_id': matiereId,
      'statut': 'non_justifiee',
    });
  }

  Future<List<Map<String, dynamic>>> getAbsencesByEleve(int eleveId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT a.*, m.nom AS matiere_nom
      FROM absences a
      JOIN matieres m ON a.matiere_id = m.id
      WHERE a.etudiant_id = ?
      ORDER BY a.date DESC, a.heure DESC
    ''', [eleveId]);
  }

  Future<void> justifyAbsence({
    required int absenceId,
    required String motif,
    String? justificatifPath,
  }) async {
    final db = await database;
    await db.update(
      'absences',
      {
        'motif': motif,
        'justificatif_path': justificatifPath,
        'statut': 'en_attente',
        'date_justification': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [absenceId],
    );
  }

  Future<void> validateJustification(int absenceId, bool approved) async {
    final db = await database;
    await db.update(
      'absences',
      {'statut': approved ? 'justifiee' : 'non_justifiee'},
      where: 'id = ?',
      whereArgs: [absenceId],
    );
  }

  // === UTILISATEURS ===
  Future<User> createUser(User user, {int? classeId}) async {
    final db = await database;
    final data = user.toMap();
    if (classeId != null) data['classe_id'] = classeId;
    final id = await db.insert('users', data);
    return user.copyWith(id: id);
  }

  Future<User?> getUserByIdentifiant(String identifiant) async {
    final db = await database;
    final maps = await db.query('users', where: 'identifiant = ?', whereArgs: [identifiant]);
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map(User.fromMap).toList();
  }

  Future<User?> login(String identifiant, String password) async {
    final user = await getUserByIdentifiant(identifiant);
    if (user == null) return null;
    return BCrypt.checkpw(password, user.password) ? user : null;
  }

  // === CLASSES & MATIÈRES ===
  Future<List<Map<String, dynamic>>> getClasses() async {
    final db = await database;
    return await db.query('classes');
  }

  Future<List<Map<String, dynamic>>> getMatieres() async {
    final db = await database;
    return await db.query('matieres');
  }

  // === LIENS ENSEIGNANT ===
  Future<void> linkTeacherToClass({required int teacherId, required int classeId}) async {
    final db = await database;
    await db.insert(
      'enseignants_classes',
      {'enseignant_id': teacherId, 'classe_id': classeId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> linkTeacherToMatiere({required int teacherId, required int matiereId}) async {
    final db = await database;
    await db.insert(
      'enseignants_matieres',
      {'enseignant_id': teacherId, 'matiere_id': matiereId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getStudentsByTeacher(int teacherId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT u.id, u.prenom, u.nom, c.nom AS classe_nom
      FROM users u
      JOIN classes c ON u.classe_id = c.id
      JOIN enseignants_classes ec ON ec.classe_id = c.id
      WHERE ec.enseignant_id = ?
      ORDER BY u.prenom
    ''', [teacherId]);
  }

  Future<List<Map<String, dynamic>>> getMatieresByTeacher(int teacherId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT m.id, m.nom
      FROM matieres m
      JOIN enseignants_matieres em ON m.id = em.matiere_id
      WHERE em.enseignant_id = ?
    ''', [teacherId]);
  }


  Future<double?> getMoyenneGenerale(int etudiantId) async {
    final matieres = await getMatieres();
    double sum = 0;
    int count = 0;

    for (var m in matieres) {
      final moyenne = await getMoyennePondereeDynamique(etudiantId, m['id'] as int);
      if (moyenne != null) {
        sum += moyenne;
        count++;
      }
    }

    return count > 0 ? sum / count : null;
  }
  // === SUPPRESSION BASE (DEV) ===
  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'edufollow.db');
    if (await databaseExists(path)) {
      await deleteDatabase(path);
      print('Base de données supprimée : $path');
    } else {
      print('Base de données non trouvée : $path');
    }
  }
}
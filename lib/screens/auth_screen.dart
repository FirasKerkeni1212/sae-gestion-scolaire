// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'student_dashboard.dart';
import 'home_screen.dart';
import 'teacher_dashboard.dart'; // AJOUTÉ
import '../database/database_helper.dart' deferred as db;

class AuthScreen extends StatefulWidget {
  final String role;
  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _dbLoaded = false;

  final Map<String, String> _roleTitles = {
    'eleve': 'Espace Étudiants',
    'parent': 'Espace Parents',
    'enseignant': 'Espace Enseignants',
    'administrateur': 'Administration & Gouvernance',
  };

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    await db.loadLibrary();
    setState(() => _dbLoaded = true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_dbLoaded) {
      _showError("Base de données en cours de chargement...");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final identifiant = _idController.text.trim();
      final password = _passwordController.text;

      final user = await db.DatabaseHelper.instance.login(identifiant, password);
      if (user == null) {
        _showError("Identifiant ou mot de passe incorrect.");
        return;
      }

      if (user.role != widget.role) {
        _showError("Accès refusé pour ce rôle.");
        return;
      }

      // === REDIRECTION SELON RÔLE ===
      if (user.role == 'eleve') {
        final helper = db.DatabaseHelper.instance;
        final database = await helper.database;

        String classe = 'Inconnue';
        if (user.id != null) {
          final result = await database.rawQuery('''
            SELECT classes.nom FROM classes
            JOIN users ON users.classe_id = classes.id
            WHERE users.id = ?
          ''', [user.id]);

          if (result.isNotEmpty) {
            classe = result.first['nom'] as String;
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDashboard(
              prenom: user.prenom,
              nom: user.nom,
              classe: classe,
              identifiant: user.identifiant,
              id: user.id!,
            ),
          ),
        );
      }

      else if (user.role == 'administrateur') {
        Navigator.pushReplacementNamed(context, '/admin');
      }

      else if (user.role == 'enseignant') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TeacherDashboard(user: user)),
        );
      }

    } catch (e) {
      _showError("Erreur : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/logo.jpg',
            height: 50,
            width: 50,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 30),
          ),
        ),
        const SizedBox(width: 12),
        const Spacer(),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Cours du Jour', style: TextStyle(color: Color(0xFFC00000), fontSize: 14)),
            Text('2025/2026', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFC00000)),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.role == 'eleve';
    final isParent = widget.role == 'parent';
    final isTeacher = widget.role == 'enseignant';
    final isAdmin = widget.role == 'administrateur';

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: _buildAppBar(),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // === BARRE DE NAVIGATION ENTRE ESPACES ===
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: _roleTitles.entries.map((e) {
                  final active = widget.role == e.key;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => AuthScreen(role: e.key)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? Colors.red : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          e.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? Colors.white : Colors.black,
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // === FORMULAIRES SELON RÔLE ===
            if (isStudent)
              _buildLoginSection(
                title: 'Espace Étudiant',
                idLabel: 'Identifiant',
                idHint: 'Votre ID',
              ),
            if (isParent)
              _buildLoginSection(
                title: 'Espace Parent',
                idLabel: 'Numéro CIN',
                idHint: 'Veuillez saisir le n° CIN de l\'étudiant',
              ),
            if (isTeacher)
              _buildTeacherLoginSection(), // REMPLACE _buildUnderConstruction()
            if (isAdmin)
              _buildLoginSection(
                title: 'Espace Administration & Gouvernance',
                idLabel: 'Identifiant',
                idHint: 'Votre ID administrateur',
              ),
          ],
        ),
      ),
    );
  }

  // === FORMULAIRE GÉNÉRIQUE ===
  Widget _buildLoginSection({
    required String title,
    required String idLabel,
    required String idHint,
  }) {
    return Expanded(
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.jpg',
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 80),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Un avenir plus clair commence ici !',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text(
                        'Protégez vos données personnelles !',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      Text(idLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _idController,
                        decoration: InputDecoration(
                          hintText: idHint,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) => v?.trim().isEmpty == true ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Connexion', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fonctionnalité à venir')),
                            );
                          },
                          child: const Text(
                            'J\'ai oublié mon mot de passe',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === FORMULAIRE ENSEIGNANT (identique au générique) ===
  Widget _buildTeacherLoginSection() {
    return _buildLoginSection(
      title: 'Espace Enseignant',
      idLabel: 'Identifiant',
      idHint: 'Votre ID enseignant',
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../database/database_helper.dart' deferred as db;
import 'package:bcrypt/bcrypt.dart';
import 'admin/absence_validation_screen.dart';
import 'home_screen.dart';
import 'admin/bulletin_generation_flow.dart'; // ← NOUVEAU

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<User> users = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> matieres = [];
  bool loading = true;

  // Pagination
  int currentPage = 0;
  int itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await db.loadLibrary();
    final allUsers = await db.DatabaseHelper.instance.getAllUsers();
    final classList = await db.DatabaseHelper.instance.getClasses();
    final matiereList = await db.DatabaseHelper.instance.getMatieres();

    setState(() {
      users = allUsers;
      classes = classList;
      matieres = matiereList;
      loading = false;
    });
  }

  // Pagination
  List<User> getPaginatedUsers() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return users.skip(startIndex).take(itemsPerPage).toList();
  }

  int get totalPages => (users.length / itemsPerPage).ceil();

  void _previousPage() {
    if (currentPage > 0) setState(() => currentPage--);
  }

  void _nextPage() {
    if (currentPage < totalPages - 1) setState(() => currentPage++);
  }

  void _showAddUserDialog() async {
    await db.loadLibrary();
    final classList = await db.DatabaseHelper.instance.getClasses();
    final matiereList = await db.DatabaseHelper.instance.getMatieres();

    final formKey = GlobalKey<FormState>();
    final identifiantCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    String? role = 'eleve';
    int? selectedClasseId;
    int? selectedMatiereId;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: const Color(0xFFFFF5F5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 20, right: 20, top: 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Nouvel utilisateur',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC00000)),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(identifiantCtrl, 'Identifiant', Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField(passwordCtrl, 'Mot de passe', Icons.lock, obscure: true),
                    const SizedBox(height: 12),
                    _buildTextField(nomCtrl, 'Nom', Icons.badge),
                    const SizedBox(height: 12),
                    _buildTextField(prenomCtrl, 'Prénom', Icons.badge_outlined),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: InputDecoration(
                        labelText: 'Rôle',
                        prefixIcon: const Icon(Icons.work, color: Color(0xFFC00000)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: Colors.white,
                      ),
                      items: [
                        {'value': 'eleve', 'label': 'Élève'},
                        {'value': 'enseignant', 'label': 'Enseignant'},
                        {'value': 'parent', 'label': 'Parent'},
                        {'value': 'admin', 'label': 'Administrateur'},
                      ].map((r) => DropdownMenuItem(value: r['value'], child: Text(r['label']!))).toList(),
                      onChanged: (v) => setModalState(() => role = v),
                    ),
                    const SizedBox(height: 12),
                    if (role == 'eleve' || role == 'enseignant') ...[
                      DropdownButtonFormField<int>(
                        value: selectedClasseId,
                        decoration: InputDecoration(
                          labelText: 'Classe',
                          prefixIcon: const Icon(Icons.school, color: Color(0xFFC00000)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true, fillColor: Colors.white,
                        ),
                        items: classList.map((c) => DropdownMenuItem(
                          value: c['id'] as int,
                          child: Text('${c['nom']} - ${c['niveau']}'),
                        )).toList(),
                        onChanged: (v) => setModalState(() => selectedClasseId = v),
                        validator: (v) => v == null ? 'Sélectionnez une classe' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (role == 'enseignant') ...[
                      DropdownButtonFormField<int>(
                        value: selectedMatiereId,
                        decoration: InputDecoration(
                          labelText: 'Matière enseignée',
                          prefixIcon: const Icon(Icons.book, color: Color(0xFFC00000)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true, fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        isExpanded: true,
                        items: matiereList.map((m) => DropdownMenuItem(
                          value: m['id'] as int,
                          child: Text(m['nom'] as String, overflow: TextOverflow.ellipsis, maxLines: 1),
                        )).toList(),
                        onChanged: (v) => setModalState(() => selectedMatiereId = v),
                        validator: (v) => v == null ? 'Sélectionnez une matière' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              await db.loadLibrary();
                              final existing = await db.DatabaseHelper.instance.getUserByIdentifiant(identifiantCtrl.text);
                              if (existing != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Identifiant déjà utilisé !'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              if ((role == 'eleve' || role == 'enseignant') && selectedClasseId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sélectionnez une classe')),
                                );
                                return;
                              }
                              if (role == 'enseignant' && selectedMatiereId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sélectionnez une matière')),
                                );
                                return;
                              }

                              final hashed = BCrypt.hashpw(passwordCtrl.text, BCrypt.gensalt());
                              final user = User(
                                identifiant: identifiantCtrl.text,
                                password: hashed,
                                nom: nomCtrl.text,
                                prenom: prenomCtrl.text,
                                role: role!,
                                classeId: role == 'eleve' ? selectedClasseId : null,
                              );

                              final created = await db.DatabaseHelper.instance.createUser(user);
                              if (created.id == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Erreur lors de la création')),
                                );
                                return;
                              }

                              if (role == 'enseignant' && selectedClasseId != null) {
                                await db.DatabaseHelper.instance.linkTeacherToClass(
                                  teacherId: created.id!,
                                  classeId: selectedClasseId!,
                                );
                                if (selectedMatiereId != null) {
                                  await db.DatabaseHelper.instance.linkTeacherToMatiere(
                                    teacherId: created.id!,
                                    matiereId: selectedMatiereId!,
                                  );
                                }
                              }

                              Navigator.pop(context);
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Utilisateur créé avec succès !'), backgroundColor: Colors.green),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC00000),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Créer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFC00000)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: Colors.white,
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
    );
  }

  String _getRoleEmoji(String role) {
    switch (role) {
      case 'admin': return 'Administrateur';
      case 'enseignant': return 'Enseignant';
      case 'parent': return 'Parent';
      case 'eleve': return 'Élève';
      default: return 'Utilisateur';
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin': return 'ADMINISTRATEUR';
      case 'enseignant': return 'ENSEIGNANT';
      case 'parent': return 'PARENT';
      case 'eleve': return 'ÉLÈVE';
      default: return role.toUpperCase();
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.orange;
      case 'enseignant': return Colors.blue;
      case 'parent': return Colors.green;
      case 'eleve': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text('Dashboard Administrateur'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFC00000)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, size: 40, color: Color(0xFFC00000)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Administrateur', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('admin@edufollow.tn', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Color(0xFFC00000)),
              title: const Text('Tableau de bord'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Color(0xFFC00000)),
              title: const Text('Ajouter un utilisateur'),
              onTap: () {
                Navigator.pop(context);
                _showAddUserDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFC00000)),
              title: const Text('Générer Bulletin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BulletinGenerationFlowScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Justifications en attente'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AbsenceValidationScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Réinitialiser BD'),
              onTap: () async {
                Navigator.pop(context);
                await db.loadLibrary();
                await db.DatabaseHelper.instance.deleteDatabaseFile();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Base de données réinitialisée !'), backgroundColor: Colors.green),
                );
                _loadData();
              },
            ),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Aucun utilisateur trouvé', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showAddUserDialog,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC00000)),
              child: const Text('Créer un utilisateur'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: getPaginatedUsers().length,
              itemBuilder: (context, i) {
                final u = getPaginatedUsers()[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(u.role).withOpacity(0.2),
                      child: Text(_getRoleEmoji(u.role), style: const TextStyle(fontSize: 24)),
                    ),
                    title: Text('${u.prenom} ${u.nom}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(u.identifiant, style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(u.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getRoleColor(u.role).withOpacity(0.3)),
                          ),
                          child: Text(
                            _getRoleLabel(u.role),
                            style: TextStyle(color: _getRoleColor(u.role), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _previousPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Précédent'),
                ),
                const SizedBox(width: 12),
                Text('Page ${currentPage + 1} sur $totalPages', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC00000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Suivant'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showAddUserDialog,
            backgroundColor: const Color(0xFFC00000),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () async {
              await db.loadLibrary();
              await db.DatabaseHelper.instance.deleteDatabaseFile();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Base de données réinitialisée !'), backgroundColor: Colors.green),
              );
              _loadData();
            },
            backgroundColor: Colors.grey,
            icon: const Icon(Icons.delete),
            label: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: isDesktop ? _buildDesktopAppBar(context) : _buildMobileAppBar(context),
          actions: isDesktop ? [] : null,
        ),
      ),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // === BIENVENUE ===
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                color: Color(0xFFC00000),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Cette page donne l\'accès à l\'intranet d\'EduFollow est réservée aux élèves, enseignants et personnel administratif.',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // === CARTES RÔLES ===
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRoleCard(context, 'Espace Étudiant', 'L\'espace étudiant renferme les informations...', 'assets/student.jpg', 'eleve'),
                    const SizedBox(width: 24),
                    _buildRoleCard(context, 'Espace Parents', 'L\'espace parents est un endroit privilégié...', 'assets/parent.jpg', 'parent'),
                    const SizedBox(width: 24),
                    _buildRoleCard(context, 'Espace Enseignant', 'L\'espace enseignant est un endroit réservé...', 'assets/teacher.jpg', 'enseignant'),
                    const SizedBox(width: 24),
                    _buildRoleCard(context, 'Administration & Gouvernance', 'L\'espace Administration & Gouvernance...', 'assets/admin.jpg', 'administrateur'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === APPBAR DESKTOP ===
  Widget _buildDesktopAppBar(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/logo.jpg',
            height: 200,
            width: 200,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 40),
          ),
        ),
        const SizedBox(width: 20),
        const Spacer(),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Cours du Jour', style: TextStyle(color: Color(0xFFC00000), fontWeight: FontWeight.bold)),
            Text('2025/2026', style: TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(width: 24),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
          child: const Text('Accueil', style: TextStyle(color: Colors.black)),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(role: 'eleve'))),
          child: const Text('Se Connecter', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  // === APPBAR MOBILE ===
  Widget _buildMobileAppBar(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
          children: [
            Text('Cours du Jour', style: TextStyle(color: Color(0xFFC00000), fontSize: 14)),
            Text('2025/2026', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  // === DRAWER MOBILE ===
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
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Se Connecter'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(role: 'eleve')));
            },
          ),
        ],
      ),
    );
  }

  // === CARTE RÔLE ===
  Widget _buildRoleCard(BuildContext context, String title, String desc, String img, String role) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuthScreen(role: role))),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      img,
                      height: 90,
                      width: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFC00000)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/home_screen.dart';
import 'database/database_helper.dart';
import 'models/user.dart';
import 'screens/admin_dashboard.dart';
import 'screens/notes/report_card.dart';
import 'screens/notes/student_notes_dashboard.dart';
import 'screens/teacher_note_input.dart';
import 'screens/parent_dashboard.dart';
import 'screens/teacher_dashboard.dart';

// NOTIFICATIONS GLOBALES
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('📱 === DÉMARRAGE EDUFOLLOW ===');

  // INITIALISE LES NOTIFICATIONS (CORRIGÉ)
  await _initializeNotifications();

  await _createAdminIfNotExists();
  await _seedInitialData();

  runApp(const EduFollowApp());
}

// ====================================================================
// INITIALISATION DES NOTIFICATIONS (CORRIGÉ)
// ====================================================================
Future<void> _initializeNotifications() async {
  debugPrint('🔔 Initialisation des notifications...');

  try {
    // Configuration Android
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration globale
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    // Initialiser le plugin
    final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('🔔 Notification cliquée: ${details.payload}');
        // Vous pouvez ouvrir le PDF ici si nécessaire
      },
    );

    debugPrint('✅ Plugin initialisé: $initialized');

    // ⚠️ CRITIQUE : CRÉER LE CANAL DE NOTIFICATION (obligatoire Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'bulletin_channel', // ID - doit correspondre au service PDF
      'Bulletins', // Nom visible
      description: 'Notifications pour les bulletins de notes générés',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('✅ Canal "bulletin_channel" créé');

    // Demander la permission (Android 13+)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      debugPrint('✅ Permission notifications: ${granted ?? false}');

      final bool? areEnabled = await androidImplementation.areNotificationsEnabled();
      debugPrint('✅ Notifications activées: ${areEnabled ?? false}');

      if (areEnabled == false) {
        debugPrint('⚠️ ATTENTION : Les notifications sont DÉSACTIVÉES !');
        debugPrint('👉 Paramètres > Applications > EduFollow > Notifications');
      }
    }

    // Notification de test au démarrage (optionnel - pour vérifier)
    await _sendTestNotification();
  } catch (e, stackTrace) {
    debugPrint('❌ ERREUR notifications: $e');
    debugPrint('Stack: $stackTrace');
  }
}

// ====================================================================
// NOTIFICATION DE TEST (pour vérifier que ça marche)
// ====================================================================
Future<void> _sendTestNotification() async {
  try {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bulletin_channel', // Même ID que le canal créé
      'Bulletins',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '🎓 EduFollow démarré',
      'Les notifications fonctionnent correctement !',
      notificationDetails,
    );

    debugPrint('✅ Notification de test envoyée');
  } catch (e) {
    debugPrint('❌ Erreur notification test: $e');
  }
}

// FONCTION : CRÉER L'ADMIN PAR DÉFAUT
Future<void> _createAdminIfNotExists() async {
  try {
    final helper = DatabaseHelper.instance;
    final existing = await helper.getUserByIdentifiant('admin');
    if (existing != null) {
      debugPrint('Admin déjà existant (ID: ${existing.id})');
      return;
    }

    final hashedPassword = BCrypt.hashpw('admin123', BCrypt.gensalt());
    await helper.createUser(
      User(
        identifiant: 'admin',
        password: hashedPassword,
        nom: 'Administrateur',
        prenom: 'EduFollow',
        role: 'administrateur',
      ),
    );
    debugPrint('✅ COMPTE ADMIN CRÉÉ');
  } catch (e) {
    debugPrint('❌ ERREUR ADMIN : $e');
  }
}

// FONCTION : INSÉRER LES DONNÉES INITIALES
Future<void> _seedInitialData() async {
  final helper = DatabaseHelper.instance;
  final database = await helper.database;

  final classesSAE = List.generate(11, (i) => {
    'nom': 'SAE${i + 1}',
    'niveau': 'SAE',
  });

  final matieresSAE = [
    'Électricité Industrielle',
    'Automatismes',
    'Électronique de Puissance',
    'Programmation Automates',
    'Réseaux Industriels',
    'Maintenance Préventive',
    'Sécurité Électrique',
    'Projets SAE',
    'Soudure & Assemblage',
    'Mesures & Contrôle',
    'Énergies Renouvelables',
    'Commande Numérique',
    'Robotique Industrielle',
    'Systèmes Embarqués',
    'CAO Électrique',
    'DAO Mécanique',
    'Hydraulique & Pneumatique',
    'Thermique Industrielle',
    'Gestion de Production',
    'Qualité & Métrologie',
    'Anglais Technique',
    'Communication Professionnelle',
    'Stage en Entreprise',
    'PFE/PI',
  ];

  final classCount = Sqflite.firstIntValue(
    await database.rawQuery('SELECT COUNT(*) FROM classes'),
  ) ??
      0;
  if (classCount == 0) {
    for (var c in classesSAE) await database.insert('classes', c);
    debugPrint('✅ 11 classes insérées');
  } else {
    debugPrint('Classes existantes ($classCount)');
  }

  final matiereCount = Sqflite.firstIntValue(
    await database.rawQuery('SELECT COUNT(*) FROM matieres'),
  ) ??
      0;
  if (matiereCount == 0) {
    for (var m in matieresSAE) await database.insert('matieres', {'nom': m});
    debugPrint('✅ 24 matières insérées');
  } else {
    debugPrint('Matières existantes ($matiereCount)');
  }
}

class EduFollowApp extends StatelessWidget {
  const EduFollowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduFollow - SAE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC00000)),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFC00000),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/admin': (_) => const AdminDashboard(),
        '/teacher': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as User;
          return TeacherDashboard(user: user);
        },
        '/parent': (_) => const ParentDashboard(),
        '/student_notes': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return StudentNotesDashboard(
            eleveId: args['eleveId'],
            eleveNom: args['eleveNom'],
          );
        },
        '/report_card': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ReportCardScreen(
            eleveId: args['eleveId'],
            eleveNom: args['eleveNom'],
          );
        },
        '/teacher_note_input': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TeacherNoteInputScreen(
            eleveId: args['eleveId'],
            eleveNom: args['eleveNom'],
            classeNom: args['classeNom'] ?? 'Inconnue',
            enseignant: args['enseignant'],
          );
        },
      },
    );
  }
}
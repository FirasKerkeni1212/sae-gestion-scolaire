// lib/services/pdf_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart'; // flutterLocalNotificationsPlugin
import '../database/database_helper.dart';

class PdfService {
  static Future<void> generateAndShareBulletin({
    required int etudiantId,
    required String nomComplet,
  }) async {
    try {
      debugPrint('=== DÉBUT GÉNÉRATION PDF ===');

      final dbHelper = DatabaseHelper.instance;

      // --- 1. Récupération des données ---
      final userList = await (await dbHelper.database).query(
        'users',
        where: 'id = ?',
        whereArgs: [etudiantId],
      );
      if (userList.isEmpty) throw Exception('Élève non trouvé');

      final userMap = userList.first;
      final classeId = userMap['classe_id'] as int?;
      String classeNom = 'Inconnue';

      if (classeId != null) {
        final classeList = await (await dbHelper.database).query(
          'classes',
          where: 'id = ?',
          whereArgs: [classeId],
        );
        if (classeList.isNotEmpty) {
          classeNom = classeList.first['nom'] as String;
        }
      }

      final notes = await dbHelper.getNotesByEleve(etudiantId);
      final matieres = await dbHelper.getMatieres();

      final moyennesMap = <int, double>{};
      for (final m in matieres) {
        final mid = m['id'] as int?;
        if (mid == null) continue;
        final avg = await dbHelper.getMoyennePondereeDynamique(etudiantId, mid);
        if (avg != null) moyennesMap[mid] = avg;
      }

      final moyenneGenerale = await dbHelper.getMoyenneGenerale(etudiantId) ?? double.nan;

      // --- 2. Logo ---
      late final pw.Widget logoWidget;
      try {
        final logoData = await rootBundle.load('assets/logo.png');
        final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
        logoWidget = pw.Image(logoImage, width: 70, height: 70, fit: pw.BoxFit.contain);
      } catch (e) {
        logoWidget = pw.Container(
          width: 70,
          height: 70,
          color: PdfColors.grey300,
          alignment: pw.Alignment.center,
          child: pw.Text('LOGO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        );
      }

      // --- 3. Création PDF ---
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginLeft: 40,
            marginTop: 40,
            marginRight: 40,
            marginBottom: 40,
          ),
          header: (_) => _buildHeader(logoWidget, classeNom, nomComplet),
          build: (_) => _buildBody(matieres, notes, etudiantId, moyennesMap, moyenneGenerale),
          footer: (_) => _buildFooter(),
        ),
      );

      // --- 4. Sauvegarde ---
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'bulletin_${nomComplet.replaceAll(' ', '_')}.pdf';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF sauvegardé: $filePath');

      // --- 5. NOTIFICATION AMÉLIORÉE ---
      await _sendBulletinNotification(nomComplet, filePath);

      // --- 6. Partage ---
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Bulletin – $nomComplet',
      );

      debugPrint('=== FIN GÉNÉRATION PDF ===');
    } catch (e, st) {
      debugPrint('❌ ERREUR PDF : $e\n$st');
      rethrow;
    }
  }

  // ===================================================================
  // NOTIFICATION AMÉLIORÉE
  // ===================================================================
  static Future<void> _sendBulletinNotification(
      String nomComplet,
      String pdfPath,
      ) async {
    try {
      // Style de notification riche avec grande icône
      final BigTextStyleInformation bigTextStyle = BigTextStyleInformation(
        'Le bulletin de notes de $nomComplet a été généré avec succès. Cliquez pour ouvrir ou partager.',
        contentTitle: '📄 Bulletin prêt !',
        summaryText: 'EduFollow',
      );

      // Configuration Android détaillée
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'bulletin_channel',
        'Bulletins',
        channelDescription: 'Notifications pour les bulletins de notes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: const Color(0xFFFF0000), // Rouge
        icon: '@mipmap/ic_launcher',
        styleInformation: bigTextStyle,
        ticker: 'Nouveau bulletin disponible',
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        // Actions sur la notification
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'open',
            'Ouvrir',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'share',
            'Partager',
            showsUserInterface: true,
          ),
        ],
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      // Générer un ID unique basé sur le timestamp
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Afficher la notification
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        '📄 Bulletin prêt !',
        'Bulletin de $nomComplet généré avec succès',
        notificationDetails,
        payload: pdfPath,
      );

      debugPrint('✅ Notification envoyée (ID: $notificationId)');
    } catch (e) {
      debugPrint('❌ Erreur notification: $e');
      // Ne pas faire échouer toute l'opération si la notification échoue
    }
  }

  // ===================================================================
  // HEADER, BODY, FOOTER (identiques à votre code existant)
  // ===================================================================
  static pw.Widget _buildHeader(
      pw.Widget logo,
      String classeNom,
      String nomComplet,
      ) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 20),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 2),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            logo,
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Edufollow',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                      color: PdfColors.red700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Année scolaire : 2025-2026'),
                  pw.Text('Classe : ${classeNom.replaceAll(' Union', '').trim()}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Élève : ${nomComplet.trim()}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'Date : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                ],
              ),
            ),
          ],
        ),
      );

  static List<pw.Widget> _buildBody(
      List<Map<String, dynamic>> matieres,
      List<Map<String, dynamic>> notes,
      int etudiantId,
      Map<int, double> moyennesMap,
      double moyenneGenerale,
      ) =>
      [
        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.red700,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'BULLETIN DE NOTES',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 25),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: ['Matière', 'CC', 'DS', 'Examen', 'Moyenne']
                  .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(h,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center),
              ))
                  .toList(),
            ),
            ...matieres.map((m) {
              final matiereId = m['id'] as int?;
              if (matiereId == null) {
                return pw.TableRow(
                    children: List.generate(5, (_) => pw.Container()));
              }
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(m['nom']?.toString() ?? ''),
                  ),
                  _noteCell(notes, etudiantId, matiereId, 'CC'),
                  _noteCell(notes, etudiantId, matiereId, 'DS'),
                  _noteCell(notes, etudiantId, matiereId, 'Examen'),
                  _avgCell(moyennesMap[matiereId]),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: moyenneGenerale.isNaN || moyenneGenerale < 10
                ? PdfColors.red50
                : PdfColors.green50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(
              color: moyenneGenerale.isNaN || moyenneGenerale < 10
                  ? PdfColors.red700
                  : PdfColors.green700,
              width: 2,
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Moyenne Générale :',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                moyenneGenerale.isNaN ? '-' : moyenneGenerale.toStringAsFixed(2),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: moyenneGenerale.isNaN || moyenneGenerale < 10
                      ? PdfColors.red700
                      : PdfColors.green700,
                ),
              ),
            ],
          ),
        ),
      ];

  static pw.Widget _buildFooter() => pw.Container(
    alignment: pw.Alignment.center,
    padding: const pw.EdgeInsets.only(top: 20),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: PdfColors.grey400, width: 1),
      ),
    ),
    child: pw.Text(
      'Généré par EduFollow © 2025',
      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
    ),
  );

  static pw.Widget _noteCell(
      List<Map<String, dynamic>> notes,
      int etudiantId,
      int matiereId,
      String type,
      ) {
    final note = notes.firstWhere(
          (n) =>
      n['etudiant_id'] == etudiantId &&
          n['matiere_id'] == matiereId &&
          n['type_note'] == type,
      orElse: () => <String, dynamic>{},
    );
    final value = note.isNotEmpty ? (note['valeur'] as num?) : null;
    final text = value != null ? value.toStringAsFixed(1) : '-';

    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _avgCell(double? avg) {
    final text = avg != null ? avg.toStringAsFixed(1) : '-';
    final color = avg != null && avg >= 10 ? PdfColors.green700 : PdfColors.red700;

    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
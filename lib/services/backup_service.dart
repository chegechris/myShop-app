import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart'; // NEW PACKAGE
import '../db/db_provider.dart';

class BackupService {

  // =========================================================
  // EXPORT: Zips DB + Images
  // =========================================================
  static Future<void> exportDatabase(BuildContext context) async {
    try {
      // 1. Setup Paths
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, 'shop_database_live.db');
      final dbFile = File(dbPath);
      final appDir = await getApplicationDocumentsDirectory();

      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No data to export.')));
        return;
      }

      // 2. Prepare Zip
      // We flush and close DB to ensure data integrity
      await DbProvider.close();

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final zipName = 'shop_backup_$dateStr.zip';
      final tempDir = await getTemporaryDirectory();
      final zipPath = join(tempDir.path, zipName);

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      // 3. Add Database to Zip
      encoder.addFile(dbFile, 'shop_database_live.db');

      // 4. Add All Images to Zip
      // We look for all .jpg files in the app's document folder
      final files = appDir.listSync();
      int imageCount = 0;
      for (var file in files) {
        if (file is File && file.path.toLowerCase().endsWith('.jpg')) {
          encoder.addFile(file, basename(file.path)); // Store only filename
          imageCount++;
        }
      }

      encoder.close();

      // 5. Share the Zip
      await Share.shareXFiles(
        [XFile(zipPath)], 
        text: 'Mpesa Shop Full Backup ($imageCount images included)'
      );

      // Re-open DB for continued use
      await DbProvider.reloadDatabase();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  // =========================================================
  // IMPORT: Unzips + Restores DB + Fixes Paths
  // =========================================================
  static Future<bool> importDatabase(BuildContext context) async {
    try {
      // 1. Pick File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'db'], // Support both old (.db) and new (.zip)
      );

      if (result == null || result.files.single.path == null) return false;
      final File selectedFile = File(result.files.single.path!);
      final isZip = selectedFile.path.toLowerCase().endsWith('.zip');

      // 2. Confirm
      bool confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Restore Backup?"),
          content: Text(isZip 
            ? "This looks like a FULL backup (Images + Data).\nIt will overwrite current data."
            : "This looks like an OLD backup (Data only).\nImages might be missing."
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("RESTORE", style: TextStyle(color: Colors.red))),
          ],
        ),
      ) ?? false;

      if (!confirm) return false;

      // 3. Close & Clean Clean Old Data
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, 'shop_database_live.db');
      final appDir = await getApplicationDocumentsDirectory();

      await DbProvider.close();
      await Future.delayed(Duration(milliseconds: 300)); // Release lock

      // Delete old DB files
      try {
        if (await File(dbPath).exists()) await File(dbPath).delete();
        if (await File('$dbPath-wal').exists()) await File('$dbPath-wal').delete();
        if (await File('$dbPath-shm').exists()) await File('$dbPath-shm').delete();
      } catch (e) { print("Cleanup error: $e"); }

      // 4. Restore Logic
      if (isZip) {
        // --- ZIP RESTORE ---
        final bytes = await selectedFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          if (file.isFile) {
            final filename = file.name;
            if (filename.endsWith('.db')) {
              // Extract DB
              File(dbPath)
                ..createSync(recursive: true)
                ..writeAsBytesSync(file.content as List<int>);
            } else if (filename.endsWith('.jpg')) {
              // Extract Image
              File(join(appDir.path, filename))
                ..createSync()
                ..writeAsBytesSync(file.content as List<int>);
            }
          }
        }
      } else {
        // --- LEGACY DB ONLY RESTORE ---
        await selectedFile.copy(dbPath);
      }

      // 5. CRITICAL: Fix Broken Image Paths in DB
      // The DB contains absolute paths from the OLD phone (e.g. /data/user/old_phone/...)
      // We need to update them to point to the NEW phone's folder.
      await DbProvider.reloadDatabase(); // Open the restored DB
      final db = await DbProvider.db;
      
      final items = await db.query('inventory');
      int fixedCount = 0;
      
      for (var item in items) {
        String? oldPath = item['imagePath'] as String?;
        if (oldPath != null && oldPath.isNotEmpty) {
          // Extract just the filename "12345.jpg"
          String filename = basename(oldPath); 
          String newPath = join(appDir.path, filename);

          // If the path is different (e.g. moved phones), update it
          if (oldPath != newPath) {
             await db.update(
               'inventory', 
               {'imagePath': newPath}, 
               where: 'id = ?', 
               whereArgs: [item['id']]
             );
             fixedCount++;
          }
        }
      }
      print("Fixed $fixedCount image paths.");

      // 6. Success & Restart
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text("Success!"),
            content: Text("Restored Data & Images.\nPaths repaired: $fixedCount"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                child: Text("RELOAD APP"),
              ),
            ],
          ),
        );
      }

      return true;

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      return false;
    }
  }
}
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DbProvider {
  static Database? _db;

  // Get database instance
  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await init();
    return _db!;
  }

  // Initialize database
  static Future<Database> init() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'shop_database_live.db');

    return await openDatabase(
      path,
      version: 5, // Incremented for quality improvements
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customer (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            id_no TEXT,
            bank_account TEXT,
            notes TEXT,
            agent TEXT,
            store TEXT,
            createdAt INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE txn (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customerId INTEGER,
            itemId INTEGER,
            type TEXT,
            totalAmount INTEGER,
            details TEXT,
            denominationLogId INTEGER, 
            timestamp INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT,
            sellingPrice REAL,
            originalPrice REAL,
            stock INTEGER DEFAULT 0,
            imagePath TEXT
          )
        ''');

        // The accounting table
        await db.execute('''
          CREATE TABLE accounting (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER,
            cashTotal INTEGER,
            mpesa1 INTEGER,
            mpesa2 INTEGER,
            coop INTEGER,
            equity INTEGER, 
            kcb INTEGER,
            airtel INTEGER,
            otherMpesa INTEGER,
            salesDisparity INTEGER,
            specialScenarios TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try { await db.execute('ALTER TABLE inventory ADD COLUMN imagePath TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE txn ADD COLUMN denominationLogId INTEGER'); } catch (_) {}
        }
        if (oldVersion < 3) {
          try { await db.execute('ALTER TABLE inventory ADD COLUMN category TEXT'); } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            await db.execute('''
              CREATE TABLE accounting (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp INTEGER,
                cashTotal INTEGER,
                mpesa1 INTEGER,
                mpesa2 INTEGER,
                coop INTEGER,
                equity INTEGER,
                kcb INTEGER,
                airtel INTEGER,
                otherMpesa INTEGER,
                salesDisparity INTEGER,
                specialScenarios TEXT
              )
            ''');
          } catch (e) { print("Error creating accounting table: $e"); }
        }
        
        // Version 5: Add Equity
        if (oldVersion < 5) {
          try {
             await db.execute('ALTER TABLE accounting ADD COLUMN equity INTEGER DEFAULT 0');
          } catch (e) { print("Error adding equity: $e"); }
        }
      },
    );
  }

  static Future<void> reloadDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    await Future.delayed(Duration(milliseconds: 200));
    await init();
  }

  // CRUD methods
  static Future<int> insert(String table, Map<String, dynamic> values) async {
    final dbClient = await db;
    return await dbClient.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> queryRaw(String sql, [List<Object?>? arguments]) async {
    final dbClient = await db;
    return await dbClient.rawQuery(sql, arguments);
  }

  static Future<List<Map<String, dynamic>>> query(
    String table, {
    String? orderBy,
    String? where,
    List<Object?>? whereArgs,
    int? limit,
  }) async {
    final dbClient = await db;
    return await dbClient.query(
      table,
      orderBy: orderBy,
      where: where,
      whereArgs: whereArgs,
      limit: limit,
    );
  }

  static Future<int> update(String table, Map<String, dynamic> values, String where, List<Object?> whereArgs) async {
    final dbClient = await db;
    return await dbClient.update(table, values, where: where, whereArgs: whereArgs);
  }

  static Future<int> delete(String table, String where, List<Object?> whereArgs) async {
    final dbClient = await db;
    return await dbClient.delete(table, where: where, whereArgs: whereArgs);
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
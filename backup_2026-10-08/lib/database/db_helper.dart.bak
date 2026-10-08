import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('grandpolimerplast_prod.db'); // Baza nomini yangi toza nomga o'tkazdik!
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final directory = Directory(join(appDocDir.path, 'GrandPolimerPlast_Data'));
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    final dbPath = join(directory.path, filePath);

    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
        onUpgrade: _onUpgradeDB,
      ),
    );

    return db;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE partners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        inn TEXT,
        type TEXT NOT NULL, 
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        category_id INTEGER NOT NULL,
        unit_id INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL, 
        type TEXT NOT NULL, 
        partner_id INTEGER, 
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL, 
        amount REAL NOT NULL, 
        unit_id INTEGER NOT NULL,
        price REAL NOT NULL, 
        total_sum REAL NOT NULL, 
        notes TEXT,
        FOREIGN KEY (partner_id) REFERENCES partners (id) ON DELETE RESTRICT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        partner_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_type TEXT NOT NULL, 
        is_incoming INTEGER NOT NULL, 
        notes TEXT,
        FOREIGN KEY (partner_id) REFERENCES partners (id) ON DELETE RESTRICT
      )
    ''');
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    // DB upgrades
  }

  Future<String> getDatabasePath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return join(appDocDir.path, 'GrandPolimerPlast_Data', 'grandpolimerplast_prod.db');
  }

  Future<void> backupDatabase(String backupFilePath) async {
    final dbPath = await getDatabasePath();
    final file = File(dbPath);
    if (await file.exists()) {
      await file.copy(backupFilePath);
    } else {
      throw Exception("Ma'lumotlar bazasi topilmadi!");
    }
  }

  Future<void> restoreDatabase(String backupFilePath) async {
    final backupFile = File(backupFilePath);
    if (await backupFile.exists()) {
      final dbPath = await getDatabasePath();
      
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      await backupFile.copy(dbPath);
      await database;
    } else {
      throw Exception("Tanlangan zaxira fayl topilmadi!");
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

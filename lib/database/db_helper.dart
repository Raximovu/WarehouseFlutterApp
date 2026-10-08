import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Zaxira faylida albatta bo'lishi kerak bo'lgan jadvallar.
  static const _requiredTables = {
    'units',
    'categories',
    'partners',
    'materials',
    'transactions',
    'payments',
  };

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('grandpolimerplast_prod.db'); // Baza nomini yangi toza nomga o'tkazdik!
    return _database!;
  }

  /// Windows/Linux uchun SQLite (FFI) fabrikasini sozlaydi.
  void _initFactory() {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> _initDB(String filePath) async {
    _initFactory();

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

  /// Tanlangan fayl haqiqiy zaxira bazasi ekanini tekshiradi:
  /// SQLite fayli, butunligi soz va ilovaning barcha jadvallari bor.
  /// Fayl faqat o'qish rejimida ochiladi — hech narsa o'zgarmaydi.
  Future<bool> _validateBackupFile(String path) async {
    Database? probe;
    try {
      probe = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );

      final check = await probe.rawQuery('PRAGMA quick_check');
      if (check.isEmpty || check.first.values.first != 'ok') return false;

      final rows = await probe.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
      final names = rows.map((r) => r['name'] as String).toSet();
      return _requiredTables.every((t) => names.contains(t));
    } catch (_) {
      return false;
    } finally {
      await probe?.close();
    }
  }

  String _timestamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)}_${two(n.hour)}-${two(n.minute)}-${two(n.second)}';
  }

  /// Zaxira fayldan bazani tiklaydi.
  ///
  /// 1) Tanlangan fayl tekshiriladi (noto'g'ri fayl bo'lsa — hech narsa o'zgarmaydi);
  /// 2) hozirgi baza alohida "Tiklashdan_oldingi_baza_..." nusxasiga saqlanadi;
  /// 3) faqat shundan keyin hozirgi baza almashtiriladi.
  ///
  /// Hozirgi bazaning xavfsizlik nusxasi yo'lini qaytaradi (nusxa olinmagan bo'lsa — null).
  Future<String?> restoreDatabase(String backupFilePath) async {
    final backupFile = File(backupFilePath);
    if (!await backupFile.exists()) {
      throw Exception("Tanlangan zaxira fayl topilmadi!");
    }

    final dbPath = await getDatabasePath();
    if (equals(backupFilePath, dbPath)) {
      throw Exception("Joriy ma'lumotlar bazasining o'zini tanlab bo'lmaydi. Zaxira nusxa faylini tanlang!");
    }

    _initFactory();
    if (!await _validateBackupFile(backupFilePath)) {
      throw Exception("Tanlangan fayl Grand Polimer Plast zaxira bazasi emas yoki buzilgan! Hech narsa o'zgartirilmadi.");
    }

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Hozirgi bazaning xavfsizlik nusxasi (tiklash xato chiqsa yoki noto'g'ri fayl tanlangan bo'lsa qaytarib olish uchun)
    final currentFile = File(dbPath);
    String? safetyPath;
    if (await currentFile.exists()) {
      safetyPath = join(dirname(dbPath), 'Tiklashdan_oldingi_baza_${_timestamp()}.db');
      await currentFile.copy(safetyPath);
    }

    try {
      // Eski bazadan qolgan yordamchi fayllar yangi faylga zarar yetkazmasligi uchun o'chiriladi
      for (final suffix in const ['-journal', '-wal', '-shm']) {
        final side = File('$dbPath$suffix');
        if (await side.exists()) await side.delete();
      }

      await backupFile.copy(dbPath);
      await database; // yangi bazani ochib ko'ramiz
    } catch (_) {
      // Xato bo'lsa — eski bazani joyiga qaytaramiz
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      if (safetyPath != null) {
        await File(safetyPath).copy(dbPath);
      }
      await database;
      rethrow;
    }

    return safetyPath;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

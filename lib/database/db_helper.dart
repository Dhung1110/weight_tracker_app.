import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;
  static final DBHelper instance = DBHelper._init();

  static const String _dbName = 'weight_tracker.db';
  static const int _dbVersion = 3;

  static const String tableUsers = 'users';
  static const String tableProfiles = 'profiles';
  static const String tableWeights = 'weights';

  DBHelper._init();

  // ================= DATABASE =================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // ================= CREATE TABLE =================
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableProfiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE,
        name TEXT,
        age INTEGER,
        height REAL,
        gender TEXT,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableWeights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        weight REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_weights_user_date ON $tableWeights(user_id, date DESC)',
    );
  }

  // ================= UPGRADE =================
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE $tableProfiles ADD COLUMN gender TEXT',
      );
    }
  }

  // ================= USERS =================
  static Future<Map<String, dynamic>?> getUser(
      String username, String password) async {
    final db = await DBHelper.instance.database;
    final result = await db.query(
      tableUsers,
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<bool> isUsernameExists(String username) async {
    final db = await DBHelper.instance.database;
    final result = await db.query(
      tableUsers,
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<int> insertUser(
      String name, String username, String password) async {
    final db = await DBHelper.instance.database;

    final userId = await db.insert(tableUsers, {
      'username': username,
      'password': password,
    });

    await db.insert(tableProfiles, {
      'user_id': userId,
      'name': name,
      'age': 25,
      'height': 1.7,
      'gender': 'Nam',
    });

    return userId;
  }

  // ================= WEIGHTS =================
  static Future<List<Map<String, dynamic>>> getWeights(int userId) async {
    final db = await DBHelper.instance.database;
    return await db.query(
      tableWeights,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  static Future<bool> insertWeight(
      int userId, double weight, String date) async {
    final db = await DBHelper.instance.database;
    try {
      await db.insert(tableWeights, {
        'user_id': userId,
        'weight': weight,
        'date': date,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteWeight(int id) async {
    final db = await DBHelper.instance.database;
    final rows =
        await db.delete(tableWeights, where: 'id = ?', whereArgs: [id]);
    return rows > 0;
  }

  // ================= PROFILE (🔥 PHẦN BỊ THIẾU) =================
  static Future<Map<String, dynamic>?> getProfile(int userId) async {
    final db = await DBHelper.instance.database;
    final result = await db.query(
      tableProfiles,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<bool> updateProfile(
      int userId, Map<String, dynamic> data) async {
    final db = await DBHelper.instance.database;
    final rows = await db.update(
      tableProfiles,
      data,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows > 0;
  }
  // Cập nhật username
  static Future<bool> updateUsername(int userId, String newUsername) async {
    final db = await instance.database;
    try {
      final rows = await db.update(
        tableUsers,
        {'username': newUsername},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return rows > 0;
    } catch (e) {
      // Lỗi ví dụ trùng username
      return false;
    }
  }

  // Đổi mật khẩu
  static Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    final db = await instance.database;
    // Kiểm tra mật khẩu cũ đúng không
    final user = await db.query(
      tableUsers,
      where: 'id = ? AND password = ?',
      whereArgs: [userId, oldPassword],
    );
    if (user.isEmpty) return false;

    final rows = await db.update(
      tableUsers,
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return rows > 0;
  }
  // Lấy username theo userId
  static Future<String?> getUsername(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      tableUsers,
      columns: ['username'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['username'] as String : null;
  }
}

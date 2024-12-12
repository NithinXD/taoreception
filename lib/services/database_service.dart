import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_credentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        password TEXT,
        mobile_number TEXT,
        email TEXT,
        app_id TEXT
      );
    ''');
  }

  Future<int> saveCredentials(Map<String, dynamic> credentials) async {
    final db = await instance.database;
    return await db.insert('user_credentials', credentials);
  }

  Future<List<Map<String, dynamic>>> fetchCredentials() async {
    final db = await instance.database;
    return await db.query('user_credentials');
  }

  Future<int> clearCredentials() async {
    final db = await instance.database;
    return await db.delete('user_credentials');
  }
}

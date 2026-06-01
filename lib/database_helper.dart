import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // En Windows 11 es mejor usar getApplicationSupportDirectory para evitar problemas de permisos
    Directory documentsDirectory = await getApplicationSupportDirectory();
    String path = join(documentsDirectory.path, 'mi_app_database.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT
      )
    ''');
  }

  Future<int> insertItem(String nombre) async {
    Database db = await database;
    return await db.insert('items', {'nombre': nombre});
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    Database db = await database;
    return await db.query('items');
  }

  Future<int> deleteItem(int id) async {
    Database db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    Database db = await database;
    return await db.delete('items');
  }
}

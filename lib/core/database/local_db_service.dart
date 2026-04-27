import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite helper for local borrowing history (Modul 5 - Internal Storage)
class LocalDbService {
  static final LocalDbService _instance = LocalDbService._();
  factory LocalDbService() => _instance;
  LocalDbService._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'borrowit_local.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE borrow_history (
            id TEXT PRIMARY KEY,
            item_name TEXT NOT NULL,
            item_image_url TEXT,
            owner_name TEXT NOT NULL,
            borrower_name TEXT NOT NULL,
            status TEXT NOT NULL,
            days INTEGER NOT NULL,
            total_price REAL NOT NULL,
            requested_at TEXT NOT NULL,
            synced_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Insert or replace a loan record from Firestore
  Future<void> upsertLoanRecord({
    required String id,
    required String itemName,
    required String itemImageUrl,
    required String ownerName,
    required String borrowerName,
    required String status,
    required int days,
    required double totalPrice,
    required DateTime requestedAt,
  }) async {
    final db = await database;
    await db.insert(
      'borrow_history',
      {
        'id': id,
        'item_name': itemName,
        'item_image_url': itemImageUrl,
        'owner_name': ownerName,
        'borrower_name': borrowerName,
        'status': status,
        'days': days,
        'total_price': totalPrice,
        'requested_at': requestedAt.toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all local history records, newest first
  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    return db.query(
      'borrow_history',
      orderBy: 'requested_at DESC',
    );
  }

  /// Clear all history records
  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('borrow_history');
  }
}

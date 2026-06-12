import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';
import '../models/soul.dart';
import '../models/dynamic_suggestion.dart';

class MemoraDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'memora.db'),
      version: 1,
      onCreate: _onCreate,
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE VIRTUAL TABLE messages USING fts5(
        role, content, timestamp, conversation_id,
        tokenize='porter unicode61'
      )
    ''');

    await db.execute('''
      CREATE TABLE messages_raw (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        conversation_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE soul (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        personality TEXT NOT NULL,
        communication_style TEXT NOT NULL,
        core_values TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE world_bible (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE dynamic_suggestions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        applied INTEGER DEFAULT 0
      )
    ''');
  }

  // Messages
  static Future<int> insertMessage(Message msg) async {
    final db = await instance;
    final id = await db.insert('messages_raw', msg.toMap());
    await db.rawInsert(
      'INSERT INTO messages(rowid, role, content, timestamp, conversation_id) VALUES(?,?,?,?,?)',
      [id, msg.role, msg.content, msg.timestamp, msg.conversationId],
    );
    return id;
  }

  static Future<List<Message>> getRecentMessages({int limit = 50}) async {
    final db = await instance;
    final rows = await db.query('messages_raw',
        orderBy: 'timestamp DESC', limit: limit);
    return rows.map((r) => Message.fromMap(r)).toList().reversed.toList();
  }

  static Future<List<Message>> searchMessages(String query,
      {int limit = 20}) async {
    final db = await instance;
    final rows = await db.rawQuery(
      'SELECT m.* FROM messages_raw m '
      'JOIN messages fts ON m.id = fts.rowid '
      'WHERE messages MATCH ? ORDER BY rank LIMIT ?',
      [query, limit],
    );
    return rows.map((r) => Message.fromMap(r)).toList();
  }

  // Soul
  static Future<void> saveSoul(Soul soul) async {
    final db = await instance;
    await db.insert('soul', soul.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Soul?> getActiveSoul() async {
    final db = await instance;
    final rows = await db.query('soul', limit: 1);
    if (rows.isEmpty) return null;
    return Soul.fromMap(rows.first);
  }

  // World Bible
  static Future<void> setWorldEntry(String key, String value) async {
    final db = await instance;
    await db.insert(
      'world_bible',
      {'key': key, 'value': value, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, String>> getWorldBible() async {
    final db = await instance;
    final rows = await db.query('world_bible');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  // Dynamic suggestions
  static Future<void> saveSuggestion(DynamicSuggestion s) async {
    final db = await instance;
    await db.insert('dynamic_suggestions', s.toMap());
  }

  static Future<bool> hasSuggestion(String type) async {
    final db = await instance;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM dynamic_suggestions WHERE type = ? AND applied = 1',
      [type],
    ));
    return (count ?? 0) > 0;
  }
}

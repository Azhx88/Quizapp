import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> init() async {
    _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'quizzapp.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE game_history ADD COLUMN quizTitle TEXT');
      await db.execute('ALTER TABLE game_history ADD COLUMN playerDetails TEXT');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE game_history ADD COLUMN quizTitle TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE game_history ADD COLUMN playerDetails TEXT');
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE quizzes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        quizId TEXT NOT NULL,
        slideType TEXT NOT NULL,
        question TEXT NOT NULL,
        mediaPath TEXT,
        funFact TEXT,
        funFactMediaPath TEXT,
        correctAnswers TEXT NOT NULL DEFAULT '[]',
        falseAnswers TEXT NOT NULL DEFAULT '[]',
        orderedItems TEXT NOT NULL DEFAULT '[]',
        correctValue REAL,
        unit TEXT,
        minValue REAL,
        maxValue REAL,
        requireExactAnswer INTEGER NOT NULL DEFAULT 0,
        typeAnswer TEXT,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (quizId) REFERENCES quizzes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE game_sessions (
        id TEXT PRIMARY KEY,
        quizId TEXT NOT NULL,
        settings TEXT NOT NULL,
        playedAt INTEGER NOT NULL,
        playerCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE player_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId TEXT NOT NULL,
        playerName TEXT NOT NULL,
        score INTEGER NOT NULL DEFAULT 0,
        correctCount INTEGER NOT NULL DEFAULT 0,
        avgTime REAL NOT NULL DEFAULT 0,
        bestStreak INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (sessionId) REFERENCES game_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE game_history (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        isHost INTEGER NOT NULL,
        score INTEGER NOT NULL,
        rank INTEGER NOT NULL,
        totalPlayers INTEGER NOT NULL,
        playedAt INTEGER NOT NULL,
        quizTitle TEXT,
        playerDetails TEXT
      )
    ''');
  }
}

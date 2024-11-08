import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;
  static Database? _db;

  static const coursesTable = "coursesTable";
  static const mediaTable = "mediaTable";
  static const chaptersTable = "chaptersTable";

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  DatabaseHelper.internal();

  _onConfigure(Database db) async {
    await db.execute("PRAGMA foreign_keys = ON");
  }

  initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "COURSES.db");
    var theDb = await openDatabase(path,
        version: 1, onCreate: _onCreate, onConfigure: _onConfigure);
    return theDb;
  }

  Future<File> getDatabaseFile() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "COURSES.db");
    File databaseFile = File(path);

    if (await databaseFile.exists()) {
      return databaseFile;
    } else {
      throw Exception("Database file not found.");
    }
  }

  void _onCreate(Database db, int version) async {
    // Create courses table
    await db.execute('''
    CREATE TABLE $coursesTable (
      id TEXT PRIMARY KEY,
      title TEXT,
      author TEXT
    )
  ''');

    // Create chapters table with a foreign key linking to coursesTable
    await db.execute('''
    CREATE TABLE $chaptersTable (
      id TEXT PRIMARY KEY,
      courseId TEXT,
      title TEXT,
      FOREIGN KEY (courseId) REFERENCES $coursesTable(id) ON DELETE CASCADE
    )
  ''');

    // Updated media table to store media for both courses and chapters
    await db.execute('''
    CREATE TABLE $mediaTable (
      id TEXT PRIMARY KEY,
      parentId TEXT,        -- Links to either course or chapter
      parentType TEXT,      -- Specifies "course" or "chapter"
      mediaType TEXT,       -- Specifies "image", "video", or "file"
      path TEXT)
  ''');
  }

  Future<List<Map<String, dynamic>>> getCoursesWithContent() async {
    var dbClient = await db;
    List<Map<String, dynamic>> courses = await dbClient.query(coursesTable);
    for (var course in courses) {
      // Get chapters for each course
      List<Map<String, dynamic>> chapters = await dbClient.query(
        'chaptersTable',
        where: 'courseId = ?',
        whereArgs: [course['id']],
      );
      for (var chapter in chapters) {
        // Get media for each chapter
        List<Map<String, dynamic>> media = await dbClient.query(
          mediaTable,
          where: 'chapterId = ?',
          whereArgs: [chapter['id']],
        );
        chapter['media'] = media; // Add media to the chapter
      }
      course['chapters'] = chapters; // Add chapters to the course
    }
    return courses;
  }



  Future close() async {
    var dbProjects = await db;
    return dbProjects.close();
  }

  Future clear() async {
    final d = await db;
  }
}

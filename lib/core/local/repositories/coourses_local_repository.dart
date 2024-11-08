import 'package:youtube_download/core/local/models/chapter_entity.dart';
import 'package:youtube_download/core/local/models/media_entity.dart';

import '../database_helper.dart';
import 'base_local_repository.dart';
import '../models/course_entity.dart';
import '../local_mapper.dart';

class CourseLocalRepository extends BaseLocalRepository
    implements LocalMapper<CourseEntity> {
  @override
  Future<int> add(CourseEntity course) async {
    var db = await dataBase.db;
    return await db.insert(DatabaseHelper.coursesTable, course.toMap());
  }

  Future<int> addMedia(MediaEntity media) async {
    var db = await dataBase.db;
    return await db.insert(DatabaseHelper.mediaTable, media.toMap());
  }

  Future<int> addChapter(ChapterEntity chapter) async {
    var db = await dataBase.db;
    return await db.insert(DatabaseHelper.chaptersTable, chapter.toMap());
  }

  @override
  Future<List<CourseEntity>> getAll() async {
    var db = await dataBase.db;
    List<Map<String, dynamic>> result = await db.query(DatabaseHelper.coursesTable);

    // List to store the modified course objects with image and chapters
    List<Map<String, dynamic>> coursesWithDetails = [];

    for (var course in result) {
      // Create a mutable copy of the read-only course map
      var courseCopy = Map<String, dynamic>.from(course);

      // Get the course image from media table
      List<Map<String, dynamic>> courseImageMedia = await db.query(
        DatabaseHelper.mediaTable,
        where: 'parentId = ? AND parentType = ? AND mediaType = ?',
        whereArgs: [course['id'], 'course', 'image'],
      );

      // Set the image path if available, otherwise null
      courseCopy['image'] = courseImageMedia.isNotEmpty ? courseImageMedia.first['path'] : null;

      // Get chapters for each course
      List<Map<String, dynamic>> chapters = await db.query(
        DatabaseHelper.chaptersTable,
        where: 'courseId = ?',
        whereArgs: [course['id']],
      );

      // List to hold mutable copies of chapters
      List<Map<String, dynamic>> chaptersList = [];

      for (var chapter in chapters) {
        // Create a mutable copy of the read-only chapter map
        var chapterCopy = Map<String, dynamic>.from(chapter);

        // Get media for each chapter
        List<Map<String, dynamic>> chapterMedia = await db.query(
          DatabaseHelper.mediaTable,
          where: 'parentId = ? AND parentType = ?',
          whereArgs: [chapter['id'], 'chapter'],
        );

        // Assign media list to chapter copy
        chapterCopy['media'] = chapterMedia;

        // Add the modified chapter to the chapters list
        chaptersList.add(chapterCopy);
      }

      // Assign the modified chapters list back to the course copy
      courseCopy['chapters'] = chaptersList;

      // Add modified course copy to the list
      coursesWithDetails.add(courseCopy);
    }

    return coursesWithDetails.map((data) => CourseEntity.fromMap(data)).toList();
  }

  @override
  Future<int> addList(List<dynamic> types) {
    throw UnimplementedError();
  }

  @override
  Future<int> delete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<int> edit(type) {
    throw UnimplementedError();
  }
}

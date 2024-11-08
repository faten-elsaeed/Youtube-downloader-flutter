import 'package:youtube_download/core/local/models/chapter_entity.dart';
import 'package:youtube_download/core/local/models/media_entity.dart';
import '../database_helper.dart';
import 'base_local_repository.dart';
import '../models/course_entity.dart';
import '../local_mapper.dart';

/*//////////////Example Usage////////////////
  _storeToLocalDataBase() async {
    final courseId = Uuid().v1();
    final chapterId = Uuid().v1();
    CourseLocalRepository().add(
      CourseEntity(
        id: courseId,
        title: _youtubeVideoDownloader.videoInfo?.title ?? '',
        author: _youtubeVideoDownloader.videoInfo?.author ?? '',
      ),
    );
    CourseLocalRepository().addChapter(
      ChapterEntity(
        id: chapterId,
        courseId: courseId,
        title:
            'chapter $chapterId ${_youtubeVideoDownloader.videoInfo?.title ?? ''}',
      ),
    );
    String localImagePath =
        await downloadAndSaveImageWithDio(linkImage, '$courseId.jpg');
    CourseLocalRepository().addMedia(
      MediaEntity(
        id: '$courseId-image',
        parentId: courseId,
        parentType: 'course',
        mediaType: 'image',
        path: localImagePath,
      ),
    );
    CourseLocalRepository().addMedia(
      MediaEntity(
        id: '$chapterId-video1',
        parentId: chapterId,
        parentType: 'chapter',
        mediaType: 'video',
        path: videoFile.path,
      ),
    );
  } */

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
    List<Map<String, dynamic>> result =
        await db.query(DatabaseHelper.coursesTable);
    List<Map<String, dynamic>> coursesWithDetails = [];
    for (var course in result) {
      var courseCopy = Map<String, dynamic>.from(course);
      List<Map<String, dynamic>> courseImageMedia = await db.query(
        DatabaseHelper.mediaTable,
        where: 'parentId = ? AND parentType = ? AND mediaType = ?',
        whereArgs: [course['id'], 'course', 'image'],
      );
      courseCopy['image'] =
          courseImageMedia.isNotEmpty ? courseImageMedia.first['path'] : null;
      List<Map<String, dynamic>> chapters = await db.query(
        DatabaseHelper.chaptersTable,
        where: 'courseId = ?',
        whereArgs: [course['id']],
      );
      List<Map<String, dynamic>> chaptersList = [];
      for (var chapter in chapters) {
        var chapterCopy = Map<String, dynamic>.from(chapter);
        List<Map<String, dynamic>> chapterMedia = await db.query(
          DatabaseHelper.mediaTable,
          where: 'parentId = ? AND parentType = ?',
          whereArgs: [chapter['id'], 'chapter'],
        );
        chapterCopy['media'] = chapterMedia;
        chaptersList.add(chapterCopy);
      }
      courseCopy['chapters'] = chaptersList;
      coursesWithDetails.add(courseCopy);
    }
    return coursesWithDetails
        .map((data) => CourseEntity.fromMap(data))
        .toList();
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

  @override
  Future<CourseEntity?> get(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<CourseEntity>> search(String character) {
    throw UnimplementedError();
  }
}



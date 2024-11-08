import 'chapter_entity.dart';

class CourseEntity {
  final String id;
  final String title;
  final String author;
  final String? image;
  final List<ChapterEntity> chapters;

  CourseEntity({
    required this.id,
    required this.title,
    required this.author,
    this.image,
    this.chapters = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
    };
  }

  factory CourseEntity.fromMap(Map<String, dynamic> map) {
    return CourseEntity(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      image: map['image'],
      chapters: (map['chapters'] as List<dynamic>?)
              ?.map((chapterData) => ChapterEntity.fromMap(chapterData))
              .toList() ??
          [],
    );
  }
}

import 'media_entity.dart';

class ChapterEntity {
  final String id;
  final String courseId; // Foreign key to link this chapter to a specific course
  final String title;
  final List<MediaEntity> media; // List to store media files (videos and files) for the chapter

  ChapterEntity({
    required this.id,
    required this.courseId,
    required this.title,
    this.media = const [], // Initialize with an empty list by default
  });

  // Convert Chapter instance to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
    };
  }

  // Create a Chapter instance from a map retrieved from the database
  factory ChapterEntity.fromMap(Map<String, dynamic> map) {
    return ChapterEntity(
      id: map['id'],
      courseId: map['courseId'],
      title: map['title'],
      media: (map['media'] as List<dynamic>?)?.map((mediaData) => MediaEntity.fromMap(mediaData)).toList() ?? [],
    );
  }
}

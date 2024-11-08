class MediaEntity {
  final String id;
  final String parentId;    // Links to a course or chapter
  final String parentType;  // "course" or "chapter"
  final String mediaType;   // "image", "video", or "file"
  final String path;        // Path to the media file

  MediaEntity({
    required this.id,
    required this.parentId,
    required this.parentType,
    required this.mediaType,
    required this.path,
  });

  // Convert Media instance to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'parentType': parentType,
      'mediaType': mediaType,
      'path': path,
    };
  }

  // Create a Media instance from a map retrieved from the database
  factory MediaEntity.fromMap(Map<String, dynamic> map) {
    return MediaEntity(
      id: map['id'],
      parentId: map['parentId'],
      parentType: map['parentType'],
      mediaType: map['mediaType'],
      path: map['path'],
    );
  }
}

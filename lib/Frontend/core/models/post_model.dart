class PostAuthor {
  final String id;
  final String name;

  PostAuthor({required this.id, required this.name});

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(id: json['_id'] ?? '', name: json['name'] ?? 'Anonymous');
  }
}

class PostComment {
  final String id;
  final PostAuthor user;
  final String text;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['_id'] ?? '',
      user: PostAuthor.fromJson(
        json['user'] is Map ? json['user'] : {'_id': json['user']},
      ),
      text: json['text'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class PostModel {
  final String id;
  final PostAuthor author;
  final String location;
  final List<String> images;
  final String caption;
  final List<String> likes;
  final List<PostComment> comments;
  final DateTime createdAt;
  final bool isEdited;
  final DateTime? editedAt;

  PostModel({
    required this.id,
    required this.author,
    required this.location,
    required this.images,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.isEdited = false,
    this.editedAt,
  });

  String get primaryImageUrl => images.isNotEmpty ? images.first : '';

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Handle both old 'imageUrl' and new 'images' fields
    List<String> imagesList = [];
    if (json['images'] != null) {
      imagesList = List<String>.from(json['images']);
    } else if (json['imageUrl'] != null) {
      imagesList = [json['imageUrl']];
    }

    return PostModel(
      id: json['_id'] ?? '',
      author: PostAuthor.fromJson(
        json['author'] is Map ? json['author'] : {'_id': json['author']},
      ),
      location: json['location'] ?? '',
      images: imagesList,
      caption: json['caption'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
      comments: (json['comments'] as List? ?? [])
          .map((c) => PostComment.fromJson(c))
          .toList(),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
    );
  }
}

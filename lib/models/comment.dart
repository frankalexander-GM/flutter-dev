/// `CommentOut` del backend FastAPI — snake_case, autor embebido.
library;

import 'post.dart';

class Comment {
  final String id;
  final String postId;
  final String content;
  final PostAuthor? author;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.content,
    this.author,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        content: json['content'] as String? ?? '',
        author: json['author'] != null
            ? PostAuthor.fromJson(json['author'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

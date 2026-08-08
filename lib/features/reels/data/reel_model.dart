import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String id;
  final String userId;
  final String videoUrl;
  final String caption;
  final DateTime createdAt;
  final List<String> likes;

  Reel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.caption,
    required this.createdAt,
    required this.likes,
  });

  factory Reel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reel(
      id: doc.id,
      userId: data['userId'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      caption: data['caption'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }
}

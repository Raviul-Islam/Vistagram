import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String userId;
  final String imageUrl;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      userId: data['userId'] ?? 'user',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static List<Story> get demoStories => [
        Story(
          id: 'demo_1',
          userId: 'sarah_photo',
          imageUrl: 'https://picsum.photos/id/1018/600/1000',
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        Story(
          id: 'demo_2',
          userId: 'alex_travels',
          imageUrl: 'https://picsum.photos/id/1015/600/1000',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        Story(
          id: 'demo_3',
          userId: 'david_vibe',
          imageUrl: 'https://picsum.photos/id/1019/600/1000',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Story(
          id: 'demo_4',
          userId: 'emma_style',
          imageUrl: 'https://picsum.photos/id/1016/600/1000',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];
}

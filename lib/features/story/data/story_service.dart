import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'story_model.dart';

final storyServiceProvider = Provider<StoryService>((ref) {
  return StoryService(FirebaseFirestore.instance, FirebaseStorage.instance);
});

final storiesProvider = StreamProvider<List<Story>>((ref) {
  return ref.watch(storyServiceProvider).getStories();
});

class StoryService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  StoryService(this._firestore, this._storage);

  Future<void> uploadStory(File image, String userId) async {
    try {
      final String storyId = _firestore.collection('stories').doc().id;
      final Reference storageRef = _storage.ref().child('stories/$storyId.jpg');
      
      final UploadTask uploadTask = storageRef.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      final String imageUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('stories').doc(storyId).set({
        'id': storyId,
        'userId': userId,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Story>> getStories() {
    return _firestore
        .collection('stories')
        .snapshots()
        .map((snapshot) {
          final dbStories = snapshot.docs
              .map((doc) => Story.fromFirestore(doc))
              .where((story) => story.imageUrl.isNotEmpty)
              .toList();
          
          dbStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return dbStories;
        });
  }
}

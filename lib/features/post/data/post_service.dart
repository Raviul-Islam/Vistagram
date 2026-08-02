import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'post_model.dart';

final postServiceProvider = Provider<PostService>((ref) {
  return PostService(FirebaseFirestore.instance, FirebaseStorage.instance);
});

final feedProvider = StreamProvider<List<Post>>((ref) {
  return ref.watch(postServiceProvider).getFeedPosts();
});

final userPostsProvider = StreamProvider.family<List<Post>, String>((ref, userId) {
  return ref.watch(postServiceProvider).getUserPosts(userId);
});

class PostService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  PostService(this._firestore, this._storage);

  Future<void> uploadPost(File image, String caption, String userId) async {
    try {
      final String postId = _firestore.collection('posts').doc().id;
      final Reference storageRef = _storage.ref().child('posts/$postId.jpg');
      
      final UploadTask uploadTask = storageRef.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      final String imageUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('posts').doc(postId).set({
        'id': postId,
        'userId': userId,
        'imageUrl': imageUrl,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Post>> getFeedPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  Stream<List<Post>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_service.dart';
import 'post_model.dart';
import 'comment_model.dart';

final postServiceProvider = Provider<PostService>((ref) {
  return PostService(FirebaseFirestore.instance, FirebaseStorage.instance);
});

final feedProvider = StreamProvider<List<Post>>((ref) {
  return ref.watch(postServiceProvider).getFeedPosts();
});

final feedPostsProvider = Provider.family<AsyncValue<List<Post>>, String>((ref, userId) {
  final profileAsync = ref.watch(userProfileProvider(userId));
  final feedAsync = ref.watch(feedProvider);

  if (profileAsync.isLoading || feedAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (profileAsync.hasError) {
    return AsyncValue.error(profileAsync.error!, profileAsync.stackTrace!);
  }
  if (feedAsync.hasError) {
    return AsyncValue.error(feedAsync.error!, feedAsync.stackTrace!);
  }

  final profile = profileAsync.value;
  final allPosts = feedAsync.value ?? [];

  if (profile == null) return const AsyncValue.data([]);

  final allowedIds = {userId, ...profile.following};
  final filtered = allPosts.where((p) => allowedIds.contains(p.userId)).toList();
  
  return AsyncValue.data(filtered);
});

final userPostsProvider = FutureProvider.family<List<Post>, String>((ref, userId) {
  return ref.watch(postServiceProvider).getUserPostsOnce(userId);
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
        'commentCount': 0,
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

  Future<List<Post>> getUserPostsOnce(String userId) async {
    final snapshot = await _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .get();
    final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Stream<List<Post>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }

  Future<void> toggleLike(String postId, String userId, List<String> currentLikes) async {
    if (currentLikes.contains(userId)) {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }

  Future<void> addComment(String postId, String userId, String text) async {
    final commentRef = _firestore.collection('posts').doc(postId).collection('comments').doc();
    await commentRef.set({
      'postId': postId,
      'userId': userId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList());
  }
}

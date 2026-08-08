import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reel_model.dart';

final reelServiceProvider = Provider<ReelService>((ref) {
  return ReelService(FirebaseFirestore.instance, FirebaseStorage.instance);
});

final reelsProvider = StreamProvider<List<Reel>>((ref) {
  return ref.watch(reelServiceProvider).getReels();
});

class ReelService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ReelService(this._firestore, this._storage);

  Future<void> uploadReel(File video, String caption, String userId) async {
    try {
      final String reelId = _firestore.collection('reels').doc().id;
      final Reference storageRef = _storage.ref().child('reels/$reelId.mp4');
      
      final UploadTask uploadTask = storageRef.putFile(
        video,
        SettableMetadata(contentType: 'video/mp4'),
      );
      final TaskSnapshot snapshot = await uploadTask;
      final String videoUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('reels').doc(reelId).set({
        'id': reelId,
        'userId': userId,
        'videoUrl': videoUrl,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Reel>> getReels() {
    return _firestore
        .collection('reels')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Reel.fromFirestore(doc)).toList());
  }
}

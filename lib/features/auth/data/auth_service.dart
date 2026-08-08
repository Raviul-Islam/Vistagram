import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_profile.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance, FirebaseStorage.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = StreamProvider.family<UserProfile?, String>((ref, uid) {
  return ref.watch(authServiceProvider).getUserProfile(uid);
});

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthService(this._auth, this._firestore, this._storage);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUpWithEmailAndPassword(String email, String password, String username) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'username': username,
          'bio': '',
          'profilePicUrl': '',
          'followers': [],
          'following': [],
          'savedPosts': [],
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Check if user is new, if so, create their profile in Firestore
      if (userCredential.user != null) {
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (!userDoc.exists) {
          // New user, create profile
          final username = googleUser.email.split('@').first;
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': googleUser.email,
            'username': username, // Simple generated username
            'bio': '',
            'profilePicUrl': googleUser.photoUrl ?? '',
            'followers': [],
            'following': [],
            'savedPosts': [],
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Stream<UserProfile?> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<String> uploadProfilePicture(String uid, File image) async {
    final ref = _storage.ref().child('profile_pictures/$uid.jpg');
    await ref.putFile(image);
    final url = await ref.getDownloadURL();
    await updateUserProfile(uid, {'profilePicUrl': url});
    return url;
  }

  Future<void> toggleSavePost(String uid, String postId, List<String> currentSaved) async {
    if (currentSaved.contains(postId)) {
      await _firestore.collection('users').doc(uid).update({
        'savedPosts': FieldValue.arrayRemove([postId]),
      });
    } else {
      await _firestore.collection('users').doc(uid).update({
        'savedPosts': FieldValue.arrayUnion([postId]),
      });
    }
  }

  Future<void> toggleFollow(String myUid, String targetUid, bool isCurrentlyFollowing) async {
    final batch = _firestore.batch();
    final myDoc = _firestore.collection('users').doc(myUid);
    final targetDoc = _firestore.collection('users').doc(targetUid);

    if (isCurrentlyFollowing) {
      batch.update(myDoc, {'following': FieldValue.arrayRemove([targetUid])});
      batch.update(targetDoc, {'followers': FieldValue.arrayRemove([myUid])});
    } else {
      batch.update(myDoc, {'following': FieldValue.arrayUnion([targetUid])});
      batch.update(targetDoc, {'followers': FieldValue.arrayUnion([myUid])});
    }
    await batch.commit();
  }
}

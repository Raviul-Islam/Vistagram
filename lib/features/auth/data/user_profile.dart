import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String username;
  final String bio;
  final String profilePicUrl;
  final List<String> followers;
  final List<String> following;
  final List<String> savedPosts;

  UserProfile({
    required this.uid,
    required this.email,
    required this.username,
    required this.bio,
    required this.profilePicUrl,
    required this.followers,
    required this.following,
    required this.savedPosts,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserProfile(
      uid: data?['uid'] ?? doc.id,
      email: data?['email'] ?? '',
      username: data?['username'] ?? '',
      bio: data?['bio'] ?? '',
      profilePicUrl: data?['profilePicUrl'] ?? '',
      followers: List<String>.from(data?['followers'] ?? []),
      following: List<String>.from(data?['following'] ?? []),
      savedPosts: List<String>.from(data?['savedPosts'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'bio': bio,
      'profilePicUrl': profilePicUrl,
      'followers': followers,
      'following': following,
      'savedPosts': savedPosts,
    };
  }
}

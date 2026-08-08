import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_model.dart';
import '../../auth/data/auth_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(FirebaseFirestore.instance);
});

final userChatsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(chatServiceProvider).getUserChats(user.uid);
});

final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  return ref.watch(chatServiceProvider).getChatMessages(chatId);
});

class ChatService {
  final FirebaseFirestore _firestore;

  ChatService(this._firestore);

  Stream<List<ChatRoom>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());
  }

  Stream<List<Message>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    // Check if chat already exists
    final QuerySnapshot query = await _firestore
        .collection('chats')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> participants = data['participantIds'] ?? [];
      if (participants.contains(otherUserId)) {
        return doc.id; // Chat already exists
      }
    }

    // Create new chat
    final newChatRef = _firestore.collection('chats').doc();
    await newChatRef.set({
      'id': newChatRef.id,
      'participantIds': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
    });

    return newChatRef.id;
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final batch = _firestore.batch();

    // Set the new message
    batch.set(messageRef, {
      'id': messageRef.id,
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update the chat room last message
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    });

    await batch.commit();
  }
}

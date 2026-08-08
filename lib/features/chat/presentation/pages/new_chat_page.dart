import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../data/chat_service.dart';
import '../../../auth/data/auth_service.dart';

final allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('users').get();
  return snapshot.docs.map((doc) => doc.data()).toList();
});

class NewChatPage extends ConsumerWidget {
  const NewChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: usersAsync.when(
        data: (users) {
          final otherUsers = users.where((u) => u['uid'] != currentUser?.uid).toList();
          
          if (otherUsers.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }

          return ListView.builder(
            itemCount: otherUsers.length,
            itemBuilder: (context, index) {
              final user = otherUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(user['username'] ?? 'User'),
                subtitle: Text(user['email'] ?? ''),
                onTap: () async {
                  final chatService = ref.read(chatServiceProvider);
                  final chatId = await chatService.createOrGetChat(currentUser!.uid, user['uid']);
                  if (context.mounted) {
                    context.pushReplacement('/chat/$chatId', extra: user['username']);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

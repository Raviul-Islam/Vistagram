import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/chat_service.dart';
import '../../../auth/data/auth_service.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: () => context.push('/inbox/new'),
          ),
        ],
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(child: Text('No messages yet.'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.participantIds.firstWhere(
                (id) => id != currentUser?.uid,
                orElse: () => 'Unknown',
              );
              // For simplicity, display uid suffix as name
              final displayUser = otherUserId.length >= 6 ? 'user_${otherUserId.substring(0, 6)}' : 'user_$otherUserId';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(displayUser, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  chat.lastMessage.isEmpty ? 'Say hi!' : chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  context.push('/chat/${chat.id}', extra: displayUser);
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../post/data/post_service.dart';
import '../../../story/presentation/widgets/stories_bar.dart';
import '../../../auth/data/auth_service.dart';
import '../../../post/data/post_model.dart';
import '../widgets/comments_sheet.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final feedAsync = ref.watch(feedPostsProvider(currentUser.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vistagram',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/inbox'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: StoriesBar()),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          feedAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No posts yet. Be the first to share!'),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _PostItem(post: posts[index]);
                }, childCount: posts.length),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error loading posts: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostItem extends ConsumerWidget {
  final Post post;
  
  const _PostItem({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider(post.userId));
    
    final displayUser = userProfileAsync.value?.username ?? 
        (post.userId.length >= 6 ? 'user_${post.userId.substring(0, 6)}' : 'user_${post.userId}');
        
    final profilePicUrl = userProfileAsync.value?.profilePicUrl;

    final currentUser = ref.watch(authStateProvider).value;
    final currentUserProfile = currentUser != null ? ref.watch(userProfileProvider(currentUser.uid)).value : null;
    
    final isLiked = currentUser != null && post.likes.contains(currentUser.uid);
    final isSaved = currentUserProfile != null && currentUserProfile.savedPosts.contains(post.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          onTap: () => context.push('/profile/${post.userId}'),
          leading: CircleAvatar(
            backgroundColor: Colors.grey[800],
            backgroundImage: profilePicUrl != null && profilePicUrl.isNotEmpty 
                ? CachedNetworkImageProvider(profilePicUrl) 
                : null,
            child: profilePicUrl == null || profilePicUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          title: Text(
            displayUser,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.more_vert),
        ),
        CachedNetworkImage(
          imageUrl: post.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: 300,
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 300,
            color: Colors.grey[900],
            child: const Icon(Icons.error),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (currentUser != null) {
                    ref.read(postServiceProvider).toggleLike(post.id, currentUser.uid, post.likes);
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(post.likes.length.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: FractionallySizedBox(
                        heightFactor: 0.7,
                        child: CommentsSheet(postId: post.id),
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline),
                    const SizedBox(width: 4),
                    Text(post.commentCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.send),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (currentUser != null && currentUserProfile != null) {
                    ref.read(authServiceProvider).toggleSavePost(currentUser.uid, post.id, currentUserProfile.savedPosts);
                  }
                },
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white),
              children: [
                TextSpan(
                  text: '$displayUser ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: post.caption),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

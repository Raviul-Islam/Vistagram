import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../auth/data/auth_service.dart';
import '../../../post/data/post_service.dart';

class ProfilePage extends ConsumerWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final isCurrentUser = userId == null || userId == user.uid;
    final targetUserId = userId ?? user.uid;

    final userProfileAsync = ref.watch(userProfileProvider(targetUserId));
    final userPostsAsync = ref.watch(userPostsProvider(targetUserId));

    return Scaffold(
      appBar: AppBar(
        title: userProfileAsync.when(
          data: (profile) => Text(
            profile?.username ?? (isCurrentUser ? user.email?.split('@').first : 'User') ?? 'Profile',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          loading: () => const Text('Loading...'),
          error: (e, st) => const Text('Profile'),
        ),
        actions: isCurrentUser
            ? [
                IconButton(
                  icon: const Icon(Icons.add_box_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                ),
              ]
            : [],
      ),
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          userProfileAsync.when(
                            data: (profile) {
                              if (profile != null && profile.profilePicUrl.isNotEmpty) {
                                return CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: NetworkImage(profile.profilePicUrl),
                                );
                              }
                              return CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[800],
                                child: const Icon(Icons.person, size: 40, color: Colors.white),
                              );
                            },
                            loading: () => const CircleAvatar(radius: 40, child: CircularProgressIndicator()),
                            error: (e, st) => const CircleAvatar(radius: 40, child: Icon(Icons.error)),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn(
                                  'Posts',
                                  userPostsAsync.value?.length.toString() ?? '0',
                                ),
                                _buildStatColumn(
                                  'Followers', 
                                  userProfileAsync.value?.followers.length.toString() ?? '0'
                                ),
                                _buildStatColumn(
                                  'Following', 
                                  userProfileAsync.value?.following.length.toString() ?? '0'
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: userProfileAsync.when(
                          data: (profile) => Text(
                            (profile != null && profile.bio.isNotEmpty) ? profile.bio : 'Welcome to Vistagram!',
                            style: const TextStyle(fontSize: 14),
                          ),
                          loading: () => const SizedBox(),
                          error: (e, st) => const SizedBox(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: isCurrentUser
                          ? Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      context.push('/edit_profile');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.grey),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Edit Profile'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      final username = userProfileAsync.value?.username ?? user.email?.split('@').first ?? 'this user';
                                      // ignore: deprecated_member_use
                                      Share.share('Check out $username\'s Vistagram profile!');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.grey),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Share Profile'),
                                  ),
                                ),
                              ],
                            )
                          : userProfileAsync.when(
                              data: (profile) {
                                if (profile == null) return const SizedBox();
                                final isFollowing = profile.followers.contains(user.uid);
                                return Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          ref.read(authServiceProvider).toggleFollow(
                                                user.uid,
                                                targetUserId,
                                                isFollowing,
                                              );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isFollowing ? Colors.grey[800] : Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(isFollowing ? 'Following' : 'Follow'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          // TODO: Navigate to chat
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: Colors.grey),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Message'),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox(),
                              error: (e, st) => const SizedBox(),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 1,
                    tabs: [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.video_library_outlined)),
                      Tab(icon: Icon(Icons.person_pin_outlined)),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _KeepAliveTab(
                child: userPostsAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async => ref.refresh(userPostsProvider(user.uid)),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No posts yet')),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(userPostsProvider(user.uid)),
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: posts[index].imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[900]),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.error),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
              const _KeepAliveTab(child: Center(child: Text('Reels'))),
              const _KeepAliveTab(child: Center(child: Text('Tagged'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.black, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

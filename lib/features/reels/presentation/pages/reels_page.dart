import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../data/reel_service.dart';
import '../../data/reel_model.dart';

class ReelsPage extends ConsumerWidget {
  const ReelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reelsAsync = ref.watch(reelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: reelsAsync.when(
        data: (reels) {
          if (reels.isEmpty) {
            return const Center(child: Text('No reels yet. Be the first to post one!'));
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (context, index) {
              return ReelPlayerItem(reel: reels[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class ReelPlayerItem extends StatefulWidget {
  final Reel reel;
  const ReelPlayerItem({super.key, required this.reel});

  @override
  State<ReelPlayerItem> createState() => _ReelPlayerItemState();
}

class _ReelPlayerItemState extends State<ReelPlayerItem> {
  late VideoPlayerController _videoController;
  bool _isPlaying = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.setLooping(true);
          _videoController.setVolume(1.0); // Start with sound as requested
          _videoController.play();
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
        _isPlaying = false;
      } else {
        _videoController.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: () {
        // Double tap to like feature can go here
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Play/Pause indicator overlay
          if (!_isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, size: 80, color: Colors.white54),
            ),

          // Mute toggle button
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 28),
              onPressed: _toggleMute,
            ),
          ),

          // Gradient for text readability
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.6, 1.0],
              ),
            ),
          ),
          
          // Content (User Info, Caption, Audio)
          Positioned(
            bottom: 20,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[800],
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.reel.userId.length >= 6 ? 'user_${widget.reel.userId.substring(0, 6)}' : 'user_${widget.reel.userId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        minimumSize: const Size(60, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Follow', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (widget.reel.caption.isNotEmpty)
                  Text(widget.reel.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.music_note, size: 16),
                    const SizedBox(width: 5),
                    const Text('Original Audio'),
                  ],
                )
              ],
            ),
          ),
          
          // Right Action Column
          Positioned(
            bottom: 20,
            right: 16,
            child: Column(
              children: [
                _buildActionItem(Icons.favorite_border, '${widget.reel.likes.length}'),
                _buildActionItem(Icons.chat_bubble_outline, '0'),
                _buildActionItem(Icons.send_outlined, 'Share'),
                _buildActionItem(Icons.more_vert, ''),
                const SizedBox(height: 10),
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.white),
          if (label.isNotEmpty) const SizedBox(height: 5),
          if (label.isNotEmpty) Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/story_model.dart';
import '../../data/story_service.dart';
import '../../../auth/data/auth_service.dart';

class LocalStoryNotifier extends Notifier<File?> {
  @override
  File? build() => null;
  void setStory(File? file) => state = file;
}
final localStoryProvider = NotifierProvider<LocalStoryNotifier, File?>(LocalStoryNotifier.new);

class UploadingStoryNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setUploading(bool value) => state = value;
}
final isUploadingStoryProvider = NotifierProvider<UploadingStoryNotifier, bool>(UploadingStoryNotifier.new);

class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  void _showAddStoryOptions(BuildContext parentContext, WidgetRef ref) {
    showModalBottomSheet(
      context: parentContext,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAndUploadStory(parentContext, ref, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAndUploadStory(parentContext, ref, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadStory(BuildContext context, WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 82,
      );
      if (pickedFile == null || !context.mounted) return;

      final authState = ref.read(authStateProvider);
      final user = authState.value;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to share a story.')),
        );
        return;
      }

      final imageFile = File(pickedFile.path);
      ref.read(localStoryProvider.notifier).setStory(imageFile);
      ref.read(isUploadingStoryProvider.notifier).setUploading(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading story...')),
      );

      await ref.read(storyServiceProvider).uploadStory(imageFile, user.uid);

      ref.read(isUploadingStoryProvider.notifier).setUploading(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story shared successfully!')),
        );
      }
    } catch (e) {
      ref.read(isUploadingStoryProvider.notifier).setUploading(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add story: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showStoryViewer(BuildContext context, {Story? story, File? localFile, bool isMyStory = false}) {
    if (story == null && localFile == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final displayUser = isMyStory
            ? 'Your Story'
            : (story != null && story.userId.length >= 6
                ? (story.userId.contains('_') ? story.userId : 'user_${story.userId.substring(0, 6)}')
                : 'user_${story?.userId ?? "You"}');

        return StoryViewerDialog(
          displayUser: displayUser,
          story: story,
          localFile: localFile,
        );
      },
    );
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);
    final authState = ref.watch(authStateProvider);
    final isUploading = ref.watch(isUploadingStoryProvider);
    final currentUser = authState.value;
    final currentUserId = currentUser?.uid;

    return SizedBox(
      height: 115,
      child: storiesAsync.when(
        data: (allStories) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: 1 + allStories.length,
            itemBuilder: (itemContext, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                  child: GestureDetector(
                    onTap: () => _showAddStoryOptions(context, ref),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[700]!, width: 1.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: ClipOval(
                                  child: Container(
                                    color: Colors.grey[900],
                                    child: const Icon(Icons.person, size: 36, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            if (isUploading)
                              const SizedBox(
                                width: 68,
                                height: 68,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blue),
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(Icons.add, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your Story',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final story = allStories[index - 1];
              final isMyStory = story.userId == currentUserId;
              final displayUser = isMyStory ? 'You' : (story.userId.length >= 6
                  ? (story.userId.contains('_') ? story.userId : 'user_${story.userId.substring(0, 6)}')
                  : 'user_${story.userId}');

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: () => _showStoryViewer(context, story: story, isMyStory: isMyStory),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.yellow, Colors.orange, Colors.red, Colors.purple],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.5),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: story.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.grey[800]),
                                  errorWidget: (context, url, err) => const Icon(Icons.person, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayUser,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Failed to load stories')),
      ),
    );
  }
}

class StoryViewerDialog extends StatefulWidget {
  final String displayUser;
  final Story? story;
  final File? localFile;

  const StoryViewerDialog({
    super.key,
    required this.displayUser,
    this.story,
    this.localFile,
  });

  @override
  State<StoryViewerDialog> createState() => _StoryViewerDialogState();
}

class _StoryViewerDialogState extends State<StoryViewerDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.localFile != null && (widget.story == null || widget.story!.imageUrl.isEmpty))
            Image.file(
              widget.localFile!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, color: Colors.white, size: 50)),
            )
          else if (widget.story != null)
            CachedNetworkImage(
              imageUrl: widget.story!.imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.white, size: 50)),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(seconds: 5),
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 2,
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[800],
                            child: const Icon(Icons.person, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.displayUser,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

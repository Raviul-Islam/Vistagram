import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../data/post_service.dart';
import '../../../auth/data/auth_service.dart';

class AddPostPage extends ConsumerStatefulWidget {
  const AddPostPage({super.key});

  @override
  ConsumerState<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends ConsumerState<AddPostPage> {
  File? _selectedImage;
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _uploadPost() async {
    if (_selectedImage == null) return;
    
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to post.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      await ref.read(postServiceProvider).uploadPost(
        _selectedImage!,
        _captionController.text.trim(),
        user.uid,
      );
      
      setState(() {
        _selectedImage = null;
        _captionController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post shared successfully!')));
      context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload post: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _selectedImage = null;
              _captionController.clear();
            });
          },
        ),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _selectedImage == null ? null : _uploadPost,
              child: Text(
                'Share',
                style: TextStyle(
                  color: _selectedImage == null ? Colors.blue.withOpacity(0.5) : Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GestureDetector(
                    onTap: () => _showPickerOptions(context),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[800],
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : const Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0, right: 12.0),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write a caption...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Add Location'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: const Text('Tag People'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

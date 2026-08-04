import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/post_service.dart';
import '../../../auth/data/auth_service.dart';

class InstantCameraPage extends ConsumerStatefulWidget {
  const InstantCameraPage({super.key});

  @override
  ConsumerState<InstantCameraPage> createState() => _InstantCameraPageState();
}

class _InstantCameraPageState extends ConsumerState<InstantCameraPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'No camera device available.';
          });
        }
        return;
      }
      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    _controller?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Camera permission or error: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1 || _isInitializing) return;
    setState(() {
      _isInitializing = true;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile picture = await _controller!.takePicture();
      _handleSelectedImage(File(picture.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take picture: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _handleSelectedImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open gallery: $e')),
        );
      }
    }
  }

  void _handleSelectedImage(File imageFile) {
    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to share a photo.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Sharing photo...')),
    );

    ref.read(postServiceProvider).uploadPost(imageFile, '', user.uid).then((_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Photo shared successfully!')),
      );
    }).catchError((error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to share photo: $error')),
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitializing)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null || _controller == null || !_controller!.value.isInitialized)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(_errorMessage ?? 'Camera unavailable', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Select from Gallery Instead'),
                    ),
                  ],
                ),
              )
            else
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),

            Positioned(
              top: 16,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.photo_library, color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 4),
                          const Text('Gallery', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_cameras.length > 1)
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
                          onPressed: _switchCamera,
                        ),
                      )
                    else
                      const SizedBox(width: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

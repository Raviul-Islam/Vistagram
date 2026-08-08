import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/post_service.dart';
import '../../../reels/data/reel_service.dart';
import '../../../auth/data/auth_service.dart';

enum CameraMode { post, reel }

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
  
  CameraMode _currentMode = CameraMode.post;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

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
      enableAudio: _currentMode == CameraMode.reel, // Enable audio for reels
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
    if (_cameras.length <= 1 || _isInitializing || _isRecording) return;
    setState(() {
      _isInitializing = true;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  void _switchMode(CameraMode mode) async {
    if (_isRecording || _currentMode == mode) return;
    setState(() {
      _currentMode = mode;
      _isInitializing = true;
    });
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _handleCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_currentMode == CameraMode.post) {
      if (_controller!.value.isTakingPicture) return;
      try {
        final XFile picture = await _controller!.takePicture();
        _handleSelectedMedia(File(picture.path), isVideo: false);
      } catch (e) {
        _showError('Failed to take picture: $e');
      }
    } else {
      // Reel mode
      if (_isRecording) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
    }
  }

  Future<void> _startRecording() async {
    if (_controller!.value.isRecordingVideo) return;
    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
        if (_recordingSeconds >= 90) { // 90 seconds limit
          _stopRecording();
        }
      });
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_controller!.value.isRecordingVideo) return;
    try {
      _recordingTimer?.cancel();
      final XFile video = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      _handleSelectedMedia(File(video.path), isVideo: true);
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isRecording) return;
    final picker = ImagePicker();
    try {
      if (_currentMode == CameraMode.post) {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          _handleSelectedMedia(File(pickedFile.path), isVideo: false);
        }
      } else {
        final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
        if (pickedFile != null) {
          _handleSelectedMedia(File(pickedFile.path), isVideo: true);
        }
      }
    } catch (e) {
      _showError('Failed to open gallery: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _handleSelectedMedia(File mediaFile, {required bool isVideo}) {
    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user == null) {
      _showError('You must be logged in to share.');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    navigator.pop(); // Close camera
    messenger.showSnackBar(
      SnackBar(content: Text(isVideo ? 'Sharing Reel...' : 'Sharing Post...')),
    );

    if (isVideo) {
      ref.read(reelServiceProvider).uploadReel(mediaFile, '', user.uid).then((_) {
        messenger.showSnackBar(const SnackBar(content: Text('Reel shared successfully!')));
      }).catchError((error) {
        messenger.showSnackBar(SnackBar(content: Text('Failed to share Reel: $error')));
      });
    } else {
      ref.read(postServiceProvider).uploadPost(mediaFile, '', user.uid).then((_) {
        messenger.showSnackBar(const SnackBar(content: Text('Post shared successfully!')));
      }).catchError((error) {
        messenger.showSnackBar(SnackBar(content: Text('Failed to share Post: $error')));
      });
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _switchMode(CameraMode.post),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _currentMode == CameraMode.post ? Colors.black54 : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'POST',
              style: TextStyle(
                color: _currentMode == CameraMode.post ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => _switchMode(CameraMode.reel),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _currentMode == CameraMode.reel ? Colors.black54 : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'REEL',
              style: TextStyle(
                color: _currentMode == CameraMode.reel ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
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

            // Top close button
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

            // Timer (if recording)
            if (_isRecording)
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '00:${_recordingSeconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),

            // Bottom controls
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeSelector(),
                  const SizedBox(height: 20),
                  Padding(
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
                          onTap: _handleCapture,
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
                                decoration: BoxDecoration(
                                  shape: _currentMode == CameraMode.reel && _isRecording ? BoxShape.rectangle : BoxShape.circle,
                                  borderRadius: _currentMode == CameraMode.reel && _isRecording ? BorderRadius.circular(8) : null,
                                  color: _currentMode == CameraMode.reel ? Colors.red : Colors.white,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

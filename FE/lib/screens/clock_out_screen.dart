import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';

class ClockOutScreen extends StatefulWidget {
  const ClockOutScreen({super.key});

  @override
  State<ClockOutScreen> createState() => _ClockOutScreenState();
}

class _ClockOutScreenState extends State<ClockOutScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isLoading = false;
  bool _cameraInitialized = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        // Use front camera if available
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _cameraInitialized = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error initializing camera: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _captureAndVerify() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Capture image
      final image = await _cameraController!.takePicture();
      final File imageFile = File(image.path);

      // Call API
      final result = await ApiService().clockOut(imageFile);

      if (mounted) {
        final status = result['status'] ?? 'unknown';

        if (status == 'recognized') {
          // Success - face recognized
          setState(() {
            _message = result['message'];
          });

          // Show success dialog
          _showResultDialog(
            'Clock-Out Successful',
            'Goodbye, ${result['name']}!\nTime: ${_formatTimestamp(result['timestamp'])}',
            true,
          );
        } else if (status == 'unrecognized') {
          // Face detected but not recognized
          setState(() {
            _message = result['message'];
          });

          _showResultDialog(
            'Clock-Out Failed',
            'Face not recognized.\nPlease ensure you are registered in the system.',
            false,
          );
        } else if (status == 'undetected') {
          // No face detected
          setState(() {
            _message = result['message'];
          });

          _showResultDialog(
            'Clock-Out Failed',
            'No face detected in image.\nPlease position your face clearly within the frame.',
            false,
          );
        } else {
          // Unknown error
          setState(() {
            _message = result['message'] ?? 'Unknown error';
          });

          _showResultDialog(
            'Clock-Out Failed',
            result['message'] ?? 'An error occurred',
            false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  void _showResultDialog(String title, String message, bool success) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (success) {
                Navigator.pop(context); // Return to dashboard
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Clock-Out', style: AppTextStyles.subheading),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: AppColors.black,
              child: _cameraInitialized && _cameraController != null
                  ? Stack(
                      children: [
                        // Camera Preview
                        Center(child: CameraPreview(_cameraController!)),

                        // Face Frame Overlay
                        Center(
                          child: Container(
                            width: 250,
                            height: 300,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),

                        // Instruction Text
                        Positioned(
                          top: 40,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            color: Colors.black54,
                            child: const Text(
                              'Position Your Face Within The Frame',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Message Display
                        if (_message != null)
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _message!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),

          // Verify Button
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: CustomButton(
              text: 'Verify',
              onPressed: _captureAndVerify,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

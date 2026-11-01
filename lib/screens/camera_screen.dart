import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const CameraScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;

  bool isReady = false;
  bool isCapturing = false;
  bool isDisposingCamera = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initCamera();
  }

  // =========================================================
  // CAMERA INITIALIZATION
  // =========================================================

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        debugPrint("No cameras available");
        return;
      }

      final newController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      controller = newController;

      await newController.initialize();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        isReady = true;
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");

      final currentController = controller;

      controller = null;

      try {
        await currentController?.dispose();
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        isReady = false;
      });
    }
  }

  // =========================================================
  // CAMERA DISPOSAL
  // =========================================================

  Future<void> _disposeCamera() async {
    if (isDisposingCamera) {
      return;
    }

    isDisposingCamera = true;

    final currentController = controller;

    controller = null;

    if (mounted) {
      setState(() {
        isReady = false;
      });
    }

    if (currentController != null) {
      try {
        await currentController.dispose();
      } catch (e) {
        debugPrint("Camera disposal error: $e");
      }
    }

    isDisposingCamera = false;
  }

  // =========================================================
  // APP LIFECYCLE
  // =========================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Release the camera when the app is no longer active.
      _disposeCamera();
    }

    if (state == AppLifecycleState.resumed &&
        mounted &&
        controller == null &&
        !isCapturing) {
      _initCamera();
    }
  }

  // =========================================================
  // CAPTURE IMAGE
  // =========================================================

  Future<void> captureImage() async {
    final currentController = controller;

    if (currentController == null ||
        !currentController.value.isInitialized ||
        isCapturing ||
        isDisposingCamera) {
      return;
    }

    setState(() {
      isCapturing = true;
    });

    try {
      // -------------------------------------------------------
      // Capture the image first.
      // -------------------------------------------------------

      final image = await currentController.takePicture();

      // -------------------------------------------------------
      // IMPORTANT:
      //
      // Release the camera BEFORE opening PreviewScreen.
      //
      // Otherwise CameraScreen remains underneath PreviewScreen
      // and its SurfaceView continues consuming buffers.
      // -------------------------------------------------------

      await _disposeCamera();

      if (!mounted) return;

      // -------------------------------------------------------
      // Replace CameraScreen rather than pushing PreviewScreen
      // on top of it.
      // -------------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            imagePath: image.path,
            subjectId: widget.subjectId,
            subjectName: widget.subjectName,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Camera capture error: $e");

      if (!mounted) return;

      setState(() {
        isCapturing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to capture image: $e")));
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    final currentController = controller;

    controller = null;

    // CameraController.dispose() returns Future, but Flutter's
    // State.dispose() cannot await it.
    //
    // Calling it here still releases the native camera resource.
    currentController?.dispose();

    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),

      appBar: AppBar(
        title: Text(widget.subjectName),

        backgroundColor: Colors.white,

        foregroundColor: Colors.black,

        elevation: 0,
      ),

      body: isReady && controller != null && controller!.value.isInitialized
          ? Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),

                    clipBehavior: Clip.antiAlias,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),

                    child: CameraPreview(controller!),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.all(20),

                  child: SizedBox(
                    width: double.infinity,

                    height: 58,

                    child: ElevatedButton.icon(
                      onPressed: isCapturing || isDisposingCamera
                          ? null
                          : captureImage,

                      icon: const Icon(Icons.camera_alt, color: Colors.white),

                      label: Text(
                        isCapturing ? "Capturing..." : "Capture Attendance",

                        style: const TextStyle(color: Colors.white),
                      ),

                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),

                        backgroundColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

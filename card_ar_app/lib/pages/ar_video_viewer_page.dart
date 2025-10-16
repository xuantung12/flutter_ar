import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:video_player/video_player.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:ui' as ui;
import 'video_selection_page.dart';

class ARVideoViewerPage extends StatefulWidget {
  final ARVideoData videoData;

  const ARVideoViewerPage({Key? key, required this.videoData}) : super(key: key);

  @override
  State<ARVideoViewerPage> createState() => _ARVideoViewerPageState();
}

class _ARVideoViewerPageState extends State<ARVideoViewerPage> {
  ArCoreController? arCoreController;
  ARKitController? arKitController;
  VideoPlayerController? videoController;
  bool isVideoPlaced = false;
  vector.Vector3? videoPosition;
  String? videoNodeName;
  double videoAspectRatio = 16 / 9;
  Timer? _videoTextureUpdateTimer;
  GlobalKey _videoKey = GlobalKey();
  Uint8List? _currentFrameBytes;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      videoController = VideoPlayerController.asset(widget.videoData.videoPath);
      await videoController!.initialize();
      
      if (videoController!.value.size.width > 0 && 
          videoController!.value.size.height > 0) {
        setState(() {
          videoAspectRatio = videoController!.value.size.width / 
                            videoController!.value.size.height;
        });
      }
      
      videoController!.setLooping(true);
      
      videoController!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
      
      // Tự động phát video khi khởi tạo xong
      videoController!.play();
      
    } catch (e) {
      print('Error initializing video: $e');
      _showSnackBar('Lỗi khi tải video: $e');
    }
  }

  @override
  void dispose() {
    _videoTextureUpdateTimer?.cancel();
    arCoreController?.dispose();
    arKitController?.dispose();
    videoController?.dispose();
    super.dispose();
  }

  void _onARCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    arCoreController!.onPlaneTap = _handleARCoreTap;
    arCoreController!.onNodeTap = _handleNodeTap;
    
    _showSnackBar('Quét xung quanh để phát hiện mặt phẳng');
  }

  void _onARKitViewCreated(ARKitController controller) {
    arKitController = controller;
    arKitController!.onARTap = _handleARKitTap;
    
    _showSnackBar('Di chuyển thiết bị để phát hiện bề mặt');
  }

  void _handleARCoreTap(List<ArCoreHitTestResult> hits) {
    if (hits.isEmpty) return;
    
    if (isVideoPlaced) {
      _togglePlayPause();
      return;
    }
    
    final hit = hits.first;
    _placeVideoARCore(hit);
  }

  void _handleARKitTap(List<ARKitTestResult> results) {
    if (results.isEmpty) return;
    
    if (isVideoPlaced) {
      _togglePlayPause();
      return;
    }
    
    final result = results.first;
    _placeVideoARKit(result);
  }

  void _handleNodeTap(String nodeName) {
    if (nodeName == videoNodeName) {
      _togglePlayPause();
    }
  }

  void _togglePlayPause() {
    if (videoController != null && videoController!.value.isInitialized) {
      setState(() {
        if (videoController!.value.isPlaying) {
          videoController!.pause();
          _showSnackBar('Video đã tạm dừng');
        } else {
          videoController!.play();
          _showSnackBar('Video đang phát');
        }
      });
    }
  }

  // Capture video frame as texture bytes
  Future<Uint8List?> _captureVideoFrame() async {
    try {
      RenderRepaintBoundary? boundary = _videoKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing frame: $e');
      return null;
    }
  }

  void _placeVideoARCore(ArCoreHitTestResult hit) async {
    if (videoController == null || !videoController!.value.isInitialized) {
      _showSnackBar('Video chưa sẵn sàng, vui lòng đợi...');
      return;
    }

    final position = hit.pose.translation;
    videoPosition = vector.Vector3(position.x, position.y, position.z);

    double width = 0.6;
    double height = width / videoAspectRatio;
    double depth = 0.002;

    // Capture initial frame
    await Future.delayed(Duration(milliseconds: 100));
    _currentFrameBytes = await _captureVideoFrame();

    final material = ArCoreMaterial(
      color: Colors.white,
      metallic: 0.0,
      roughness: 1.0,
      textureBytes: _currentFrameBytes,
    );

    final cube = ArCoreCube(
      size: vector.Vector3(width, height, depth),
      materials: [material],
    );

    videoNodeName = 'video_node_${DateTime.now().millisecondsSinceEpoch}';

    final node = ArCoreNode(
      name: videoNodeName,
      shape: cube,
      position: videoPosition!,
      rotation: vector.Vector4(1, 0, 0, -1.5708),
    );

    arCoreController!.addArCoreNodeWithAnchor(node);
    
    setState(() {
      isVideoPlaced = true;
    });

    if (!videoController!.value.isPlaying) {
      videoController!.play();
    }

    // Start updating video texture
    _startTextureUpdate();

    _showSnackBar('Video đã được đặt! Tap vào để play/pause');
  }

  void _placeVideoARKit(ARKitTestResult result) async {
    if (videoController == null || !videoController!.value.isInitialized) {
      _showSnackBar('Video chưa sẵn sàng, vui lòng đợi...');
      return;
    }

    final transform = result.worldTransform;
    videoPosition = vector.Vector3(
      transform.getColumn(3).x,
      transform.getColumn(3).y,
      transform.getColumn(3).z,
    );

    double width = 0.6;
    double height = width / videoAspectRatio;

    try {
      // Capture initial frame
      await Future.delayed(Duration(milliseconds: 100));
      _currentFrameBytes = await _captureVideoFrame();

      // ARKit chỉ hỗ trợ color property, không hỗ trợ texture từ bytes trực tiếp
      // Nên sử dụng fallback color
      final material = ARKitMaterial(
        diffuse: ARKitMaterialProperty.color(
          Colors.grey.shade800,
        ),
        doubleSided: true,
        lightingModelName: ARKitLightingModel.constant,
      );

      final plane = ARKitPlane(
        width: width,
        height: height,
        materials: [material],
      );

      videoNodeName = 'video_node_${DateTime.now().millisecondsSinceEpoch}';

      final cameraPosition = vector.Vector3(
        transform.getColumn(3).x,
        transform.getColumn(3).y,
        transform.getColumn(3).z + 1.0,
      );
      
      final direction = cameraPosition - videoPosition!;
      direction.normalize();
      
      final angle = vector.Vector2(direction.x, direction.z).angleToSigned(vector.Vector2(0, 1));

      final node = ARKitNode(
        geometry: plane,
        position: videoPosition!,
        eulerAngles: vector.Vector3(0, angle, 0),
      );

      arKitController!.add(node, parentNodeName: null);
      
      setState(() {
        isVideoPlaced = true;
      });

      if (!videoController!.value.isPlaying) {
        videoController!.play();
      }

      // Start updating video texture (chỉ cho ARCore)
      if (Platform.isAndroid) {
        _startTextureUpdate();
      }

      _showSnackBar('Video đã được đặt! Tap để play/pause');
      
    } catch (e) {
      print('Error placing video in ARKit: $e');
      _showSnackBar('Lỗi khi đặt video: $e');
    }
  }

  void _startTextureUpdate() {
    _videoTextureUpdateTimer?.cancel();
    
    // Chỉ update cho ARCore vì ARKit không hỗ trợ dynamic texture update
    if (!Platform.isAndroid) return;
    
    // Update texture every 100ms (about 10 FPS for better performance)
    _videoTextureUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) async {
        if (!mounted || !isVideoPlaced || videoController == null) {
          timer.cancel();
          return;
        }
        
        if (videoController!.value.isPlaying && arCoreController != null) {
          // Capture new frame
          Uint8List? newFrame = await _captureVideoFrame();
          
          if (newFrame != null && videoNodeName != null) {
            _currentFrameBytes = newFrame;
            
            try {
              // Remove old node
              arCoreController!.removeNode(nodeName: videoNodeName!);
              
              // Create updated material with new frame
              final material = ArCoreMaterial(
                color: Colors.white,
                metallic: 0.0,
                roughness: 1.0,
                textureBytes: _currentFrameBytes,
              );

              double width = 0.6;
              double height = width / videoAspectRatio;
              double depth = 0.002;

              final cube = ArCoreCube(
                size: vector.Vector3(width, height, depth),
                materials: [material],
              );

              final node = ArCoreNode(
                name: videoNodeName,
                shape: cube,
                position: videoPosition!,
                rotation: vector.Vector4(1, 0, 0, -1.5708),
              );

              arCoreController!.addArCoreNodeWithAnchor(node);
            } catch (e) {
              print('Error updating ARCore texture: $e');
            }
          }
        }
      },
    );
  }

  void _resetVideo() {
    if (Platform.isAndroid && arCoreController != null && videoNodeName != null) {
      try {
        arCoreController!.removeNode(nodeName: videoNodeName!);
      } catch (e) {
        print('Error removing node: $e');
      }
    } else if (Platform.isIOS && arKitController != null && videoNodeName != null) {
      try {
        arKitController!.remove(videoNodeName!);
      } catch (e) {
        print('Error removing node: $e');
      }
    }
    
    _videoTextureUpdateTimer?.cancel();
    _currentFrameBytes = null;
    
    setState(() {
      isVideoPlaced = false;
      videoPosition = null;
      videoNodeName = null;
    });
    
    videoController?.seekTo(Duration.zero);
    videoController?.play();
    
    _showSnackBar('Nhấn vào mặt phẳng để đặt video mới');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // AR View
          if (Platform.isAndroid)
            ArCoreView(
              onArCoreViewCreated: _onARCoreViewCreated,
              enableTapRecognizer: true,
              enablePlaneRenderer: true,
              enableUpdateListener: true,
            )
          else if (Platform.isIOS)
            ARKitSceneView(
              onARKitViewCreated: _onARKitViewCreated,
              planeDetection: ARPlaneDetection.horizontalAndVertical,
              enableTapRecognizer: true,
              showFeaturePoints: true,
              showWorldOrigin: false,
            ),

          // Hidden video player for frame capture (chỉ cho Android)
          if (Platform.isAndroid)
            Positioned(
              left: -1000,
              top: -1000,
              child: RepaintBoundary(
                key: _videoKey,
                child: videoController != null && videoController!.value.isInitialized
                    ? SizedBox(
                        width: 320,
                        height: 320 / videoAspectRatio,
                        child: VideoPlayer(videoController!),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

          // Video Preview nhỏ ở góc
          if (isVideoPlaced && 
              videoController != null && 
              videoController!.value.isInitialized)
            Positioned(
              bottom: 120,
              right: 20,
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 150,
                  height: 150 / videoAspectRatio,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VideoPlayer(videoController!),
                        if (!videoController!.value.isPlaying)
                          Container(
                            color: Colors.black.withValues(alpha: 0.54),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.54),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Preview',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top Bar
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.videoData.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (videoController != null && 
                                videoController!.value.isInitialized)
                              Text(
                                '${videoController!.value.size.width.toInt()}x${videoController!.value.size.height.toInt()} • ${videoAspectRatio.toStringAsFixed(2)}:1',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                // Instructions
                if (!isVideoPlaced)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            Platform.isAndroid 
                              ? 'Quét xung quanh, sau đó nhấn vào mặt phẳng để đặt video'
                              : 'Di chuyển thiết bị, sau đó nhấn để đặt video',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          Platform.isAndroid 
                            ? 'Video đang phát trong AR! Di chuyển để xem'
                            : 'Video đã đặt! (iOS chỉ hiển thị placeholder)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.refresh,
                      label: 'Đặt lại',
                      color: Colors.orange,
                      onPressed: isVideoPlaced ? _resetVideo : null,
                    ),
                    _buildControlButton(
                      icon: videoController?.value.isPlaying ?? false
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      label: videoController?.value.isPlaying ?? false
                          ? 'Tạm dừng'
                          : 'Phát',
                      color: Colors.blue,
                      onPressed: videoController != null &&
                              videoController!.value.isInitialized
                          ? _togglePlayPause
                          : null,
                    ),
                    _buildControlButton(
                      icon: Icons.replay,
                      label: 'Phát lại',
                      color: Colors.purple,
                      onPressed: videoController != null &&
                              videoController!.value.isInitialized
                          ? () {
                              videoController!.seekTo(Duration.zero);
                              videoController!.play();
                              setState(() {});
                              _showSnackBar('Đang phát lại video');
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator
          if (videoController == null || !videoController!.value.isInitialized)
            Container(
              color: Colors.black.withValues(alpha: 0.87),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Đang tải ${widget.videoData.name}...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Vui lòng đợi trong giây lát',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isEnabled ? Colors.white : Colors.grey.shade300,
              shape: BoxShape.circle,
              boxShadow: isEnabled ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ] : [],
            ),
            child: IconButton(
              icon: Icon(icon, size: 32),
              color: isEnabled ? color : Colors.grey,
              onPressed: onPressed,
              splashRadius: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isEnabled ? Colors.white : Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:video_player/video_player.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../models/card_data.dart';

class ARCameraPage extends StatefulWidget {
  const ARCameraPage({super.key});

  @override
  State<ARCameraPage> createState() => _ARCameraPageState();
}

class _ARCameraPageState extends State<ARCameraPage> {
  // Controllers
  ArCoreController? _arCoreController;
  ARKitController? _arKitController;
  VideoPlayerController? _videoController;
  
  // State variables
  String? _detectedCardId;
  bool _isVideoPlaying = false;
  bool _isProcessing = false;
  final List<CardData> _cards = CardData.getAllCards();
  String _statusMessage = 'Đang tìm kiếm thẻ bài...';
  String? _currentVideoNodeName;
  
  @override
  void dispose() {
    _arCoreController?.dispose();
    _arKitController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ============ ANDROID ARCORE ============
  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;
    _arCoreController!.onPlaneTap = _handleArCorePlaneTap;
    _arCoreController!.onNodeTap = _handleArCoreNodeTap;
    
    // Thiết lập image tracking
    _setupArCoreImageTracking();
  }

  Future<void> _setupArCoreImageTracking() async {
    try {
      // Thông báo sẵn sàng
      setState(() {
        _statusMessage = 'Sẵn sàng! Hướng camera vào thẻ bài';
      });

      // Lắng nghe sự kiện phát hiện ảnh
      _arCoreController?.onTrackingImage = (ArCoreAugmentedImage image) {
        _onImageDetectedArCore(image);
      };
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi: ${e.toString()}';
      });
    }
  }

  void _onImageDetectedArCore(ArCoreAugmentedImage image) {
    if (_detectedCardId == image.name) return;
    
    setState(() {
      _detectedCardId = image.name;
      final card = CardData.getCardById(image.name);
      _statusMessage = 'Phát hiện ${card?.name ?? "thẻ bài"}! Tap vào màn hình để đặt video';
    });
    
    HapticFeedback.mediumImpact();
  }

  void _handleArCorePlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isEmpty || _isProcessing || _detectedCardId == null) return;
    
    final hit = hits.first;
    _placeVideoOnArCore(hit);
  }

  void _handleArCoreNodeTap(String nodeName) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
    }
  }

  Future<void> _placeVideoOnArCore(ArCoreHitTestResult hit) async {
    if (_isVideoPlaying || _detectedCardId == null) return;
    
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang tải video...';
    });

    try {
      final card = CardData.getCardById(_detectedCardId!);
      if (card == null) {
        throw Exception('Không tìm thấy thẻ bài');
      }

      // Khởi tạo video player
      _videoController = VideoPlayerController.asset(card.videoPath);
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();

      // Tạo material với màu trắng (placeholder cho video)
      final material = ArCoreMaterial(
        color: Colors.white,
      );

      // Tính kích thước video với tỷ lệ thẻ bài
      final videoWidth = 0.2;
      final videoHeight = videoWidth * card.aspectRatio;
      
      // Tạo plane để hiển thị video
      final videoNode = ArCoreNode(
       
        position: hit.pose.translation,
        rotation: hit.pose.rotation,
      );

      _currentVideoNodeName = videoNode.name;
      await _arCoreController?.addArCoreNode(videoNode);

      setState(() {
        _isVideoPlaying = true;
        _isProcessing = false;
        _statusMessage = 'Video đang phát! Di chuyển camera để xem';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Lỗi phát video: ${e.toString()}';
      });
      
      _videoController?.dispose();
      _videoController = null;
    }
  }

  // ============ IOS ARKIT ============
  void _onARKitViewCreated(ARKitController controller) {
    _arKitController = controller;
    _arKitController!.onAddNodeForAnchor = _handleARKitAnchor;
    
    setState(() {
      _statusMessage = 'Sẵn sàng! Hướng camera vào thẻ bài';
    });
  }

  void _handleARKitAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitImageAnchor) {
      _onImageDetectedARKit(anchor);
    }
  }

  void _onImageDetectedARKit(ARKitImageAnchor anchor) {
    if (_detectedCardId == anchor.referenceImageName) return;
    
    setState(() {
      _detectedCardId = anchor.referenceImageName;
      final card = CardData.getCardById(anchor.referenceImageName!);
      _statusMessage = 'Phát hiện ${card?.name ?? "thẻ bài"}! Đang đặt video...';
    });
    
    HapticFeedback.mediumImpact();
    
    // Tự động đặt video khi phát hiện thẻ
    _placeVideoOnARKit(anchor);
  }

  Future<void> _placeVideoOnARKit(ARKitImageAnchor anchor) async {
    if (_isVideoPlaying || _detectedCardId == null) return;
    
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang tải video...';
    });

    try {
      final card = CardData.getCardById(_detectedCardId!);
      if (card == null) {
        throw Exception('Không tìm thấy thẻ bài');
      }

      // Khởi tạo video player
      _videoController = VideoPlayerController.asset(card.videoPath);
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();

      // Tính kích thước video
      final videoWidth = 0.2;
      final videoHeight = videoWidth * card.aspectRatio;

      // Tạo plane cho video
      final plane = ARKitPlane(
        width: videoWidth,
        height: videoHeight,
        materials: [
          ARKitMaterial(
            diffuse: ARKitMaterialProperty.color(Colors.white),
          ),
        ],
      );

      // Tạo node và thêm vào scene
      final node = ARKitNode(
        geometry: plane,
        position: vector.Vector3(
          anchor.transform.getColumn(3).x,
          anchor.transform.getColumn(3).y,
          anchor.transform.getColumn(3).z,
        ),
      );

      _arKitController?.add(node);

      setState(() {
        _isVideoPlaying = true;
        _isProcessing = false;
        _statusMessage = 'Video đang phát! Di chuyển camera để xem';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Lỗi phát video: ${e.toString()}';
      });
      
      _videoController?.dispose();
      _videoController = null;
    }
  }

  // ============ COMMON FUNCTIONS ============
  void _resetAR() {
    setState(() {
      _isVideoPlaying = false;
      _detectedCardId = null;
      _isProcessing = false;
      _statusMessage = 'Đang tìm kiếm thẻ bài...';
    });
    
    _videoController?.dispose();
    _videoController = null;
    
    if (Platform.isAndroid && _currentVideoNodeName != null) {
      _arCoreController?.removeNode(nodeName: _currentVideoNodeName!);
      _currentVideoNodeName = null;
    }
  }

  // ============ UI BUILD ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // AR View
          if (Platform.isAndroid)
            ArCoreView(
              onArCoreViewCreated: _onArCoreViewCreated,
              enableTapRecognizer: true,
              enableUpdateListener: true,
            )
          else if (Platform.isIOS)
            ARKitSceneView(
              onARKitViewCreated: _onARKitViewCreated,
              detectionImagesGroupName: 'AR Resources',
            ),

          // Top UI - Status và Close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Close button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status message
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom UI - Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Detected card info
                      if (_detectedCardId != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Đã phát hiện: ${CardData.getCardById(_detectedCardId!)?.name ?? ""}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Reset button
                          if (_isVideoPlaying)
                            _buildControlButton(
                              icon: Icons.refresh,
                              label: 'Làm lại',
                              onPressed: _resetAR,
                              color: Colors.orange,
                            ),

                          // Play/Pause button
                          if (_videoController != null &&
                              _videoController!.value.isInitialized)
                            _buildControlButton(
                              icon: _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              label: _videoController!.value.isPlaying
                                  ? 'Tạm dừng'
                                  : 'Phát',
                              onPressed: () {
                                setState(() {
                                  if (_videoController!.value.isPlaying) {
                                    _videoController!.pause();
                                  } else {
                                    _videoController!.play();
                                  }
                                });
                              },
                              color: Colors.blue,
                            ),
                        ],
                      ),

                      // Instructions
                      if (!_isVideoPlaying && _detectedCardId != null && Platform.isAndroid)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Chạm vào màn hình để đặt video',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đang xử lý...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            iconSize: 32,
            onPressed: onPressed,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
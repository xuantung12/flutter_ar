import 'package:flutter/material.dart';
import 'ar_video_viewer_page.dart';

class ARVideoData {
  final String id;
  final String name;
  final String description;
  final String videoPath;
  final IconData icon;

  ARVideoData({
    required this.id,
    required this.name,
    required this.description,
    required this.videoPath,
    required this.icon,
  });
}

class VideoSelectionPage extends StatelessWidget {
  const VideoSelectionPage({Key? key}) : super(key: key);

  // Danh sách video AR có sẵn
  static final List<ARVideoData> arVideos = [
    ARVideoData(
      id: 'ar_video_1',
      name: 'Video AR 1',
      description: 'Trải nghiệm thực tế ảo tăng cường đầu tiên',
      videoPath: 'assets/ar_videos/ar_video_1.mp4',
      icon: Icons.play_circle_filled,
    ),
    ARVideoData(
      id: 'ar_video_2',
      name: 'Video AR 2',
      description: 'Khám phá không gian 3D tương tác',
      videoPath: 'assets/ar_videos/ar_video_2.mp4',
      icon: Icons.view_in_ar,
    ),
    ARVideoData(
      id: 'ar_video_3',
      name: 'Video AR 3',
      description: 'Hành trình thực tế ảo đặc biệt',
      videoPath: 'assets/ar_videos/ar_video_3.mp4',
      icon: Icons.threed_rotation,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade400,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Chọn Video AR',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Video List
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: arVideos.length,
                  itemBuilder: (context, index) {
                    final video = arVideos[index];
                    return _buildVideoCard(context, video);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, ARVideoData video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ARVideoViewerPage(videoData: video),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    video.icon,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        video.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

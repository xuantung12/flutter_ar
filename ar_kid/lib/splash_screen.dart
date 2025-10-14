import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/videos/splash.mp4');
    
    try {
      await _controller.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      
      _controller.play();
      
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          _navigateToHome();
        }
      });
    } catch (e) {
      // Nếu không load được video, chuyển thẳng sang home
      Future.delayed(const Duration(seconds: 2), () {
        _navigateToHome();
      });
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade300,
      body: Center(
        child: _isVideoInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Quiz Vui Nhộn',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
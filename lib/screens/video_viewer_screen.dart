import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class VideoViewerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoViewerScreen({super.key, required this.videoUrl});

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    debugPrint('VideoViewerScreen: videoUrl = \'${widget.videoUrl}\'');
    if (widget.videoUrl.startsWith('http')) {
      debugPrint('Using VideoPlayerController.network');
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    } else {
      debugPrint('Using VideoPlayerController.file');
      _videoPlayerController = VideoPlayerController.file(File(widget.videoUrl));
    }
    _videoPlayerController
        .initialize()
        .then((_) {
          debugPrint('VideoPlayerController initialized. isInitialized = \'${_videoPlayerController.value.isInitialized}\'');
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoPlayerController,
              autoPlay: true,
              looping: false,
              aspectRatio: _videoPlayerController.value.aspectRatio,
            );
          });
        })
        .catchError((e) {
          debugPrint('❌ Video init error: $e');
        });
    _videoPlayerController.addListener(() {
      debugPrint('VideoPlayerController status: isInitialized = \'${_videoPlayerController.value.isInitialized}\', hasError = \'${_videoPlayerController.value.hasError}\', errorDescription = \'${_videoPlayerController.value.errorDescription}\'');
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building VideoViewerScreen. chewieController = \'${_chewieController != null}\', isInitialized = \'${_chewieController?.videoPlayerController.value.isInitialized}\'');
    return Scaffold(
      appBar: AppBar(title: const Text('Processed Video')),
      body: Center(
        child: _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }
} 
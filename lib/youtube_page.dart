import 'package:flutter/material.dart';
import 'package:youtube_download/helpers/youtube_video_downloader.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;

const String linkYoutube = 'https://youtu.be/rYEDA3JcQqw?si=cC2FI0sfGGoXGiCy';
const idYoutube = 'rYEDA3JcQqw';

class YoutubePage extends StatefulWidget {
  const YoutubePage({super.key});

  @override
  _YoutubePageState createState() => _YoutubePageState();
}

class _YoutubePageState extends State<YoutubePage> {
  VideoPlayerController? _videoPlayerController;
  double _downloadProgress = 0.0;
  bool _isVideoReady = false;
  String _title = '';
  bool _errorOccurred = false;
  late YoutubeVideoDownloader _youtubeVideoDownloader;

  @override
  void initState() {
    super.initState();
    _initializeDownloader();
  }

  Future<void> _initializeDownloader() async {
    setState(() => _errorOccurred = false);
    _youtubeVideoDownloader = YoutubeVideoDownloader(
      linkYoutube,
      idYoutube,
      onDownloadProgress: (percentage) =>
          setState(() => _downloadProgress = percentage),
    );

    try {
      final videoFile = await _youtubeVideoDownloader.download();
      setState(() {
        _title = _youtubeVideoDownloader.videoInfo?.title ?? '';
        _videoPlayerController = VideoPlayerController.file(videoFile);
        _isVideoReady = true;
      });

      _initializeVideoPlayer();
    } catch (e) {
      developer.log("Error downloading video: $e");
      setState(() => _errorOccurred = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download video")),
      );
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    await _videoPlayerController?.initialize();
    _videoPlayerController?.setLooping(true);
    _videoPlayerController?.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: _isVideoReady && _videoPlayerController != null
            ? AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _errorOccurred
                    ? [
                        ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(Colors.deepPurple)),
                          onPressed: () => _initializeDownloader(),
                          child: Text(
                            'Try Again',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ]
                    : [
                        CircularProgressIndicator(value: _downloadProgress),
                        const SizedBox(height: 10),
                        Text(
                          '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
              ),
      ),
      floatingActionButton: _isVideoReady
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _videoPlayerController!.value.isPlaying
                      ? _videoPlayerController!.pause()
                      : _videoPlayerController!.play();
                });
              },
              child: Icon(
                _videoPlayerController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}

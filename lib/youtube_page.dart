import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_download/core/local/models/chapter_entity.dart';
import 'package:youtube_download/core/local/models/course_entity.dart';
import 'package:youtube_download/core/local/models/media_entity.dart';
import 'package:youtube_download/core/local/repositories/coourses_local_repository.dart';
import 'dart:developer' as developer;

import 'core/helpers/youtube_video_downloader.dart';

// const String linkYoutube = 'https://youtu.be/PfU4cG3WZF8?si=axTCK0gk3Lq4qhkk'; //da7e7 28 min video took 6 min

// const String linkYoutube =
//     'https://youtu.be/rYEDA3JcQqw?si=cC2FI0sfGGoXGiCy'; //adele

const String linkYoutube = 'https://youtu.be/ZK-rNEhJIDs?si=4B4y34mIQrnbTwPi';
const String linkImage =
    'https://hips.hearstapps.com/hmg-prod/images/adele-attends-the-brit-awards-2022-at-the-o2-arena-on-news-photo-1709739132.jpg';

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
  bool _isMerging = false;
  late File videoFile;

  late YoutubeVideoDownloader _youtubeVideoDownloader;

  @override
  void initState() {
    super.initState();
    _initializeDownloader();
    // _getFromLocalDataBase();
  }

  Future<void> _initializeDownloader() async {
    setState(() => _errorOccurred = false);
    _youtubeVideoDownloader = YoutubeVideoDownloader(
      linkYoutube,
      onDownloadProgress: (percentage) =>
          setState(() => _downloadProgress = percentage),
      onMergeProgress: (isMerging) => setState(() => _isMerging = isMerging),
    );

    try {
      videoFile = await _youtubeVideoDownloader.download();
      setState(() {
        _title = _youtubeVideoDownloader.videoInfo?.title ?? '';
        _videoPlayerController = VideoPlayerController.file(videoFile);
        _isVideoReady = true;
      });

      _initializeVideoPlayer();
      _storeToLocalDataBase();
    } catch (e) {
      developer.log("Error downloading video: $e");
      setState(() => _errorOccurred = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download video")),
      );
    }
  }

  _getFromLocalDataBase() async {
    CourseLocalRepository().getAll().then(
      (value) {
        courses = value;
        for (var c in courses) {
          print('${c.toMap()}');
        }
        print(
            'courses[1].chapters.firstOrNull?.media.firstOrNull?.path ${courses[1].chapters.firstOrNull?.media.firstOrNull?.path}');

        videoFile = File(
            courses[1].chapters.firstOrNull?.media.firstOrNull?.path ?? '');
        setState(() {
          _title = courses.firstOrNull?.chapters.firstOrNull?.title ?? '';
          _videoPlayerController = VideoPlayerController.file(videoFile);
          _isVideoReady = true;
          _initializeVideoPlayer();
        });
      },
    );
  }

  List<CourseEntity> courses = [];

  _storeToLocalDataBase() async {
    final courseId = Uuid().v1();
    final chapterId = Uuid().v1();

    CourseLocalRepository().add(
      CourseEntity(
        id: courseId,
        title: _youtubeVideoDownloader.videoInfo?.title ?? '',
        author: _youtubeVideoDownloader.videoInfo?.author ?? '',
      ),
    );
    CourseLocalRepository().addChapter(
      ChapterEntity(
        id: chapterId,
        courseId: courseId,
        title:
            'chapter $chapterId ${_youtubeVideoDownloader.videoInfo?.title ?? ''}',
      ),
    );
    String localImagePath =
        await downloadAndSaveImageWithDio(linkImage, '$courseId.jpg');
    CourseLocalRepository().addMedia(
      MediaEntity(
        id: '$courseId-image',
        parentId: courseId,
        parentType: 'course',
        mediaType: 'image',
        path: localImagePath,
      ),
    );

    CourseLocalRepository().addMedia(
      MediaEntity(
        id: '$chapterId-video1',
        parentId: chapterId,
        parentType: 'chapter',
        mediaType: 'video',
        path: videoFile.path,
      ),
    );
  }

  Future<String> downloadAndSaveImageWithDio(
      String imageUrl, String imageName) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String imagePath = '${directory.path}/$imageName';
    try {
      await Dio().download(imageUrl, imagePath);
      return imagePath;
    } catch (e) {
      throw Exception("Failed to download image: $e");
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
                    : _isMerging
                        ? [
                            CircularProgressIndicator(),
                            const SizedBox(height: 10),
                            Text(
                              'Video processing ...',
                              style: const TextStyle(fontSize: 18),
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

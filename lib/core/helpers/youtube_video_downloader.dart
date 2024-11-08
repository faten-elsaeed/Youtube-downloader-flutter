import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:developer' as developer;

/* //////// Example Usage //////////
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
    } catch (e) {
      developer.log("Error downloading video: $e");
      setState(() => _errorOccurred = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download video")),
      );
    }
  }
* */

class YoutubeVideoDownloader {
  final String url;
  final Function(double percentage)? onDownloadProgress;
  final Function(bool isMerging)? onMergeProgress;
  final YoutubeExplode _yt = YoutubeExplode();
  Video? videoInfo;
  late String _title;
  late String _mergedFilePath;

  YoutubeVideoDownloader(this.url,
      {this.onDownloadProgress, this.onMergeProgress});

  void _dispose() => _yt.close();

  Future<Video> _getVideoInfo() async {
    if (videoInfo == null) {
      videoInfo = await _yt.videos.get(url);
      _title = videoInfo!.title;
      developer.log('Video info - Title: $_title');
    }
    return videoInfo!;
  }

  Future<File> download() async {
    await _getVideoInfo();
    final manifest = await _getStreamManifest();
    final videoOnly = manifest.videoOnly.bestQuality;
    final audioOnly = manifest.audioOnly.withHighestBitrate();

    final totalVideoBytes = videoOnly.size.totalBytes;
    final totalAudioBytes = audioOnly.size.totalBytes;

    final List<File> downloadedFiles = await Future.wait([
      _downloadStream(
          _yt.videos.streams.get(videoOnly), 'video', totalVideoBytes),
      _downloadStream(
          _yt.videos.streams.get(audioOnly), 'audio', totalAudioBytes),
    ]);

    onMergeProgress?.call(true);
    await _mergeAudioAndVideo(downloadedFiles[0].path, downloadedFiles[1].path);
    onMergeProgress?.call(false);
    _dispose();
    return File(_mergedFilePath);
  }

  Future<StreamManifest> _getStreamManifest() async {
    return await _yt.videos.streams.getManifest(extractVideoId(url));
  }

  Future<File> _downloadStream(
      Stream<List<int>> stream, String type, int totalBytes) async {
    final filePath = await _getFilePath(type);
    final file = File(filePath);
    final sink = file.openWrite();
    int receivedBytes = 0;

    developer.log('Starting $type download to $filePath');
    await for (final data in stream) {
      sink.add(data);
      receivedBytes += data.length;
      if (type == 'video') onDownloadProgress?.call(receivedBytes / totalBytes);
    }
    await sink.close();
    developer.log('$type download complete for $filePath');
    return file;
  }

  Future<String> _getFilePath(String type) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_title${type == 'video' ? '_video.mp4' : '_audio.mp3'}';
  }

  Future<void> _mergeAudioAndVideo(String videoPath, String audioPath) async {
    final directory = await getApplicationDocumentsDirectory();
    _mergedFilePath = '${directory.path}/${_title}_merged.mp4';

    final ffmpegCommand =
        '-i "$videoPath" -i "$audioPath" -c:v copy -c:a aac -strict experimental "$_mergedFilePath"';
    await FFmpegKit.execute(ffmpegCommand);

    developer.log('Merging complete: $_mergedFilePath');
  }

  String? extractVideoId(String url) {
    final regExp = RegExp(
      r'^(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }
}

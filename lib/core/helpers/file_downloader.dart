import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class FileDownloader {
  Future<File> download(String url, String name) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/$name';
    try {
      await Dio().download(url, path);
      return File(path);
    } catch (e) {
      throw Exception("Failed to download image: $e");
    }
  }
}

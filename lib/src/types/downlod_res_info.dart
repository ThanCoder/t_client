// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

class DownlodResInfo {
  const DownlodResInfo({
    required this.response,
    required this.statusCode,
    required this.contentLength,
    required this.savePath,
    required this.isCanceled,
  });

  final HttpClientResponse response;
  final int statusCode;
  final int contentLength;
  final String savePath;
  final bool isCanceled;

  @override
  String toString() {
    return 'DownlodResInfo(response: $response, statusCode: $statusCode, contentLength: $contentLength, savePath: $savePath, isCanceled: $isCanceled)';
  }
}

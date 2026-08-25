// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

class ResInfo {
  const ResInfo({
    required this.response,
    required this.statusCode,
    required this.contentLength,
    required this.body,
  });

  final HttpClientResponse response;
  final int statusCode;
  final int contentLength;
  final String body;

  @override
  String toString() {
    return 'ResInfo(response: $response, statusCode: $statusCode, contentLength: $contentLength, body: $body)';
  }
}

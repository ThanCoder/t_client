// ignore_for_file: unused_import

import 'dart:io';

import 'package:t_client/t_client.dart';

void main() async {
  final t = TClient();
  final url =
      'https://prod-images.merino.prod.webservices.mozgcp.net/wikimedia_potd/2026-08-25/thumbnail.jpeg';
  await t.downloadProgress(
    url,
    url.split('/').last,
    onProgress: (progress) {
      print('progress: ${(progress * 100).toStringAsFixed(2)}%');
    },
  );
}

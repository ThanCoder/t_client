import 'dart:async';
import 'dart:io';

import 'index.dart';

enum StreamProgressStatus { preparing, progress, done, error }

class UploadStreamProgress {
  final int loaded;
  final int total;
  final double progress; // 0..1
  final String? errorMessage;
  final bool isCanceled;
  final StreamProgressStatus progressStatus;

  UploadStreamProgress({
    required this.progressStatus,
    this.loaded = 0,
    this.total = 0,
    this.progress = 0,
    this.errorMessage,
    this.isCanceled = false,
  });
}

class DownloadStreamProgress {
  final int receive; // 0..100
  final int total; // 0..100
  final double speed;
  final Duration? eta;
  final String? errorMessage;
  final bool isCanceled;
  final StreamProgressStatus progressStatus;

  DownloadStreamProgress({
    required this.progressStatus,
    this.speed = 0.0,
    this.eta,
    this.receive = 0,
    this.total = 0,
    this.errorMessage,
    this.isCanceled = false,
  });
}

Stream<UploadStreamProgress> httpUploadStream(
  TClient client, {
  required String path,
  required File file,
  TClientToken? token,
}) {
  final controller = StreamController<UploadStreamProgress>();
  (() async {
    try {
      controller.add(
        UploadStreamProgress(
          progressStatus: StreamProgressStatus.preparing,
          total: file.lengthSync(),
        ),
      );
      await client.upload(
        path,
        file: file,
        token: token,
        onUploadProgress: (sent, total) {
          double progress = total > 0 ? (sent / total) : 0.0;
          controller.add(
            UploadStreamProgress(
              progressStatus: StreamProgressStatus.progress,
              total: total,
              loaded: sent,
              progress: progress,
            ),
          );
        },
        onError: (message) {
          controller.add(
            UploadStreamProgress(
              progressStatus: StreamProgressStatus.error,
              total: file.lengthSync(),
              errorMessage: message,
              isCanceled: true,
            ),
          );
          controller.close();
        },
        onCancelCallback: (message) {
          controller.add(
            UploadStreamProgress(
              progressStatus: StreamProgressStatus.error,
              total: file.lengthSync(),
              errorMessage: message,
              isCanceled: true,
            ),
          );
          controller.close();
        },
      );
      controller.add(
        UploadStreamProgress(progressStatus: StreamProgressStatus.done),
      );
    } catch (e) {
      controller.add(
        UploadStreamProgress(
          progressStatus: StreamProgressStatus.error,
          total: file.lengthSync(),
          errorMessage: e.toString(),
          isCanceled: true,
        ),
      );
      controller.close();
    }
  })();

  return controller.stream;
}

Stream<DownloadStreamProgress> httpDownloadStream(
  TClient client,
  String path, {
  required String savePath,
  TClientToken? token,
  Map<String, String>? query,
  Map<String, String>? headers,
}) {
  final controller = StreamController<DownloadStreamProgress>();
  (() async {
    try {
      controller.add(
        DownloadStreamProgress(progressStatus: StreamProgressStatus.preparing),
      );

      await client.download(
        path,
        savePath: savePath,
        token: token,
        query: query,
        headers: headers,
        onReceiveProgressSpeed: (receive, total, speed, eta) {
          controller.add(
            DownloadStreamProgress(
              progressStatus: StreamProgressStatus.progress,
              eta: eta,
              receive: receive,
              total: total,
              speed: speed,
            ),
          );
        },
        onCancelCallback: (message) {
          controller.add(
            DownloadStreamProgress(
              progressStatus: StreamProgressStatus.error,
              errorMessage: message,
              isCanceled: true,
            ),
          );
          controller.close();
        },
        onError: (message) {
          controller.add(
            DownloadStreamProgress(
              progressStatus: StreamProgressStatus.error,
              errorMessage: message,
            ),
          );
          controller.close();
        },
      );

      controller.add(
        DownloadStreamProgress(progressStatus: StreamProgressStatus.done),
      );
      controller.close();
    } catch (e) {
      controller.add(
        DownloadStreamProgress(
          progressStatus: StreamProgressStatus.error,
          errorMessage: e.toString(),
          isCanceled: true,
        ),
      );
      controller.close();
    }
  })();

  return controller.stream;
}

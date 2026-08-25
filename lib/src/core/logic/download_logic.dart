// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../t_client.dart';

class DownloadToken {
  DownloadToken({required this.onCancelFileDelete});
  final bool onCancelFileDelete;

  bool _isCancel = false;
  void cance() {
    _isCancel = true;
  }
}

mixin DownloadLogic on IClient {
  Future<Result<DownlodResInfo, String>> downloadProgress(
    String url,
    String savePath, {
    DownloadToken? token,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final req = await request(url);
      final res = await req.close();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return Err('Download failed: ${res.statusCode}');
      }

      // file
      final file = File(savePath);
      await file.parent.create(recursive: true);
      final sink = file.openWrite();

      int rec = 0;
      final total = res.contentLength;

      try {
        await for (var chunk in res) {
          if (token?._isCancel ?? false) {
            break;
          }

          rec += chunk.length;
          sink.add(chunk);

          if (total > 0) {
            onProgress(rec / total);
          }
        }
      } finally {
        await sink.close();
      }
      if (token != null && token._isCancel && token.onCancelFileDelete) {
        await file.delete();
      }

      return Ok(
        .new(
          response: res,
          statusCode: res.statusCode,
          contentLength: res.contentLength,
          savePath: savePath,
          isCanceled: token?._isCancel ?? false,
        ),
      );
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// download file
  Future<Result<DownlodResInfo, String>> download(
    String url,
    String savePath, {
    DownloadToken? token,
  }) async {
    try {
      final req = await request(url);
      final res = await req.close();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return Err('Download failed: ${res.statusCode}');
      }

      final file = File(savePath);

      await file.parent.create(recursive: true);

      final sink = file.openWrite();
      await res.pipe(sink);

      return Ok(
        .new(
          response: res,
          statusCode: res.statusCode,
          contentLength: res.contentLength,
          savePath: savePath,
          isCanceled: token?._isCancel ?? false,
        ),
      );
    } catch (e) {
      return Err(e.toString());
    }
  }
}

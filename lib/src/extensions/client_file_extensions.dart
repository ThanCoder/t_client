import 'dart:convert';
import 'dart:io';

import 'package:t_client/t_client.dart';

extension ClientFileExtensions on TClient {
  ///
  /// ### File Upload Stream
  ///
  Stream<UploadStreamProgress> uploadStream(
    String path, {
    required File file,
    TClientToken? token,
  }) {
    return httpUploadStream(this, path: path, file: file, token: token);
  }

  ///
  /// ### File Download Stream
  ///
  Stream<DownloadStreamProgress> downloadStream(
    String path, {
    required String savePath,
    TClientToken? token,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) {
    return httpDownloadStream(
      this,
      path,
      savePath: savePath,
      token: token,
      headers: headers,
      query: query,
    );
  }

  ///
  /// File download with progress
  ///
  /// `supported partial download [206]`
  ///
  ///
  Future<File> download(
    String path, {
    required String savePath,
    Map<String, String>? query,
    Map<String, String>? headers,
    TClientToken? token,
    OnCancelCallback? onCancelCallback,
    void Function(String message)? onError,
    OnReceiveProgressCallback? onReceiveProgress,
    OnReceiveProgressSpeedCallback? onReceiveProgressSpeed,
  }) async {
    final file = File(savePath);
    int downloadedLength = file.existsSync() ? await file.length() : 0;

    try {
      final uri = Uri.parse(
        '${options.baseUrl}$path',
      ).replace(queryParameters: query);
      // timeout
      final request = await ioClient.getUrl(uri).timeout(options.sendTimeout);

      // Default + custom headers
      final allHeaders = {...options.headers, ...?headers};
      allHeaders.forEach((key, value) => request.headers.set(key, value));

      if (downloadedLength > 0) {
        // Range header ထည့် → offset ကနေစပြီး တောင်း
        request.headers.set('Range', 'bytes=$downloadedLength-');
      }

      final response = await request.close().timeout(options.receiveTimeout);
      // progress
      int received = 0;
      int total = response.contentLength;
      final startTime = DateTime.now();
      // header
      final contentRange = response.headers.value(
        HttpHeaders.contentRangeHeader,
      );
      if (contentRange != null) {
        // Content-Range: bytes 1000-9999/50000
        final match = RegExp(r'bytes \d+-\d+/(\d+)').firstMatch(contentRange);
        if (match != null) {
          total = int.parse(match.group(1)!);
        }
      }

      /// partial download
      if (response.statusCode == 206) {
        // Server support
        TClientLogger.instance.showLog(
          "Resume with Range OK",
          tag: 'downloadResume',
        );
        received = downloadedLength;
        final raf = file.openSync(mode: FileMode.append);

        await response.forEach((chunk) {
          // cancel token
          if (token?.isCanceled ?? false) {
            raf.close();
            if (token!.isCancelFileDelete) {
              file.deleteSync(); // Delete partial file
            }
            onCancelCallback?.call(token.onCancelMessage);
            throw Exception(token.onCancelMessage);
          }
          // write
          raf.writeFromSync(chunk);
          received += chunk.length;
          // progress
          if (onReceiveProgressSpeed != null && total > 0) {
            final elapsed = DateTime.now().difference(startTime);
            final elapsedSec = elapsed.inMilliseconds / 1000.0;
            final speed = elapsedSec > 0
                ? received / elapsedSec
                : 0.0; // bytes per second
            final eta = speed > 0
                ? Duration(seconds: ((total - received) / speed).round())
                : null;
            onReceiveProgressSpeed.call(received, total, speed, eta);
          }

          if (onReceiveProgress != null && total > 0) {
            onReceiveProgress(received, total);
          }
        });
        await raf.close();
      }
      // Server not support → overwrite trick
      else if (response.statusCode == 200) {
        // Server က file တစ်ခုလုံးပေးတာ

        final raf = file.openSync(mode: FileMode.write);

        await response.forEach((chunk) {
          // cancel token
          if (token?.isCanceled ?? false) {
            raf.close();
            if (token!.isCancelFileDelete) {
              file.deleteSync(); // Delete partial file
            }
            onCancelCallback?.call(token.onCancelMessage);
            throw Exception(token.onCancelMessage);
          }
          // write file
          raf.writeFromSync(chunk);
          received += chunk.length;

          // progress
          if (onReceiveProgressSpeed != null && total > 0) {
            final elapsed = DateTime.now().difference(startTime);
            final elapsedSec = elapsed.inMilliseconds / 1000.0;
            final speed = elapsedSec > 0
                ? received / elapsedSec
                : 0.0; // bytes per second
            final eta = speed > 0
                ? Duration(seconds: ((total - received) / speed).round())
                : null;
            onReceiveProgressSpeed.call(received, total, speed, eta);
          }

          if (onReceiveProgress != null && total > 0) {
            onReceiveProgress(received, total);
          }
        });

        await raf.close();
      }
    } catch (e) {
      TClientLogger.instance.showLog(e.toString(), tag: 'downloadResume');
      onError?.call(e.toString());
    }
    return file;
  }

  ///
  /// File upload with progress
  ///
  Future<TClientResponse?> upload(
    String path, {
    required File file,
    Map<String, String>? query,
    Map<String, String>? fields,
    Map<String, String>? headers,
    void Function(int sent, int total)? onUploadProgress,
    OnCancelCallback? onCancelCallback,
    void Function(String message)? onError,
    TClientToken? token,
  }) async {
    try {
      final uri = buildUri(path, query);
      final request = await ioClient.postUrl(uri).timeout(options.sendTimeout);
      setHeaders(request, headers);

      // 1. Boundary တည်ဆောက်ခြင်း
      final boundary =
          '----dart-boundary-${DateTime.now().millisecondsSinceEpoch}';
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      // 2. Data အားလုံး၏ Total Size ကို ကြိုတင်တွက်ချက်ခြင်း (Progress အတွက်)
      final filename = file.path.split(Platform.isWindows ? r'\' : '/').last;
      final fileLength = await file.length();

      // Header နှင့် End boundary bytes များ
      final fileHeader = utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="file"; filename="$filename"\r\n'
        'Content-Type: application/octet-stream\r\n\r\n',
      );
      final endBoundary = utf8.encode('\r\n--$boundary--\r\n');

      int fieldsSize = 0;
      List<List<int>> fieldBytesList = [];
      if (fields != null) {
        fields.forEach((key, value) {
          final part = utf8.encode(
            '--$boundary\r\nContent-Disposition: form-data; name="$key"\r\n\r\n$value\r\n',
          );
          fieldBytesList.add(part);
          fieldsSize += part.length;
        });
      }

      final totalSize =
          fieldsSize + fileHeader.length + fileLength + endBoundary.length;
      request.contentLength =
          totalSize; // Size အတိအကျပေးခြင်းဖြင့် server error ကင်းစေသည်

      int sent = 0;

      // 3. Form Fields များပို့ခြင်း
      for (var bytes in fieldBytesList) {
        request.add(bytes);
        sent += bytes.length;
        onUploadProgress?.call(sent, totalSize);
      }

      // 4. File Header ပို့ခြင်း
      request.add(fileHeader);
      sent += fileHeader.length;

      // 5. File Content ကို Stream ဖြင့်ပို့ခြင်း
      final fileStream = file.openRead();
      await for (final chunk in fileStream) {
        if (token?.isCanceled ?? false) {
          request.abort();
          onCancelCallback?.call(token!.onCancelMessage);
          throw Exception(token!.onCancelMessage);
        }
        request.add(chunk);
        sent += chunk.length;
        onUploadProgress?.call(sent, totalSize);
      }

      // 6. End Boundary ပို့ခြင်း
      request.add(endBoundary);
      sent += endBoundary.length;
      onUploadProgress?.call(sent, totalSize);

      // 7. Response ရယူခြင်း
      final response = await request.close().timeout(options.receiveTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      return TClientResponse(
        statusCode: response.statusCode,
        headers: getResponseHeaders(response),
        data: responseBody,
      );
    } catch (e) {
      TClientLogger.instance.showLog(e.toString(), tag: 'upload');
      onError?.call(e.toString());
      rethrow;
    }
  }
}

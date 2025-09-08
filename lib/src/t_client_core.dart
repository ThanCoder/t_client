import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:t_client/src/t_client_logger.dart';

import 'index.dart';

typedef Interceptor =
    FutureOr<HttpResponse> Function(
      HttpClientRequest request,
      Future<HttpResponse> Function() next,
    );

typedef OnReceiveProgressCallback = void Function(int received, int total);
typedef OnReceiveProgressSpeedCallback =
    void Function(double progress, double speed, Duration? eta);
typedef OnCancelCallback = void Function(String message);

class TClient {
  final TClientOptions options;
  final HttpClient client;

  TClient({HttpClient? client, TClientOptions? options})
    : options = options ?? const TClientOptions(),
      client = HttpClient() {
    // Apply proxy if provided
    if (this.options.proxy != null) {
      this.client.findProxy = (Uri uri) {
        return 'PROXY ${this.options.proxy}';
      };
    }
    // Optional: global client settings
    this.client.connectionTimeout = this.options.connectTimeout;
  }

  /// GET request
  Future<TClientResponse> get(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) {
    return _send('GET', path, query: query, headers: headers);
  }

  /// POST request
  Future<TClientResponse> post(
    String path, {
    Map<String, String>? query,
    Object? data,
    Map<String, String>? headers,
  }) {
    return _send('POST', path, body: data, headers: headers, query: query);
  }

  /// POST request
  Future<TClientResponse> put(
    String path, {
    Map<String, String>? query,
    Object? data,
    Map<String, String>? headers,
  }) {
    return _send('PUT', path, body: data, headers: headers, query: query);
  }

  /// POST request
  Future<TClientResponse> delete(
    String path, {
    Object? data,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) {
    return _send('DELETE', path, body: data, headers: headers, query: query);
  }

  ///
  /// File download with progress
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
      final request = await client.getUrl(uri).timeout(options.sendTimeout);

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
            client.close();
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
            onReceiveProgressSpeed.call((received / total), speed, eta);
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

        //print("Server no Range, fallback merge");
        final raf = file.openSync(mode: FileMode.writeOnlyAppend);

        int skipped = 0;
        await response.forEach((chunk) {
          // cancel token
          if (token?.isCanceled ?? false) {
            raf.close();
            client.close();
            if (token!.isCancelFileDelete) {
              file.deleteSync(); // Delete partial file
            }
            onCancelCallback?.call(token.onCancelMessage);
            throw Exception(token.onCancelMessage);
          }

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
            onReceiveProgressSpeed.call((received / total), speed, eta);
          }

          if (onReceiveProgress != null && total > 0) {
            onReceiveProgress(received, total);
          }

          if (skipped < downloadedLength) {
            final remain = downloadedLength - skipped;
            // စစ်ဆေး
            if (chunk.length <= remain) {
              skipped += chunk.length;
              TClientLogger.instance.showLog(
                "skip ${chunk.length} bytes",
                tag: 'downloadResume',
              );
              return; // skip this chunk completely
            } else {
              // raf.setPositionSync(downloadedLength);
              raf.writeFromSync(chunk.sublist(remain));
              skipped += chunk.length;
            }
          } else {
            raf.writeFromSync(chunk);
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

  /// File upload with progress
  Future<TClientResponse?> upload(
    String path, {
    required File file,
    Map<String, String>? query,
    Map<String, String>? fields, // extra form fields
    Map<String, String>? headers,
    void Function(int sent, int total)? onUploadProgress,
    OnCancelCallback? onCancelCallback,
    void Function(String message)? onError,
    TClientToken? token,
  }) async {
    try {
      final uri = Uri.parse(
        '${options.baseUrl}$path',
      ).replace(queryParameters: query);
      // timeout
      final request = await client.postUrl(uri).timeout(options.sendTimeout);
      // Merge headers
      final allHeaders = {...options.headers, ...?headers};
      allHeaders.forEach((key, value) => request.headers.set(key, value));

      final boundary =
          '----dart-http-boundary-${DateTime.now().millisecondsSinceEpoch}';
      request.headers.set(
        'Content-Type',
        'multipart/form-data; boundary=$boundary',
      );

      // Important: avoid HttpException
      request.contentLength = -1;

      final fileLength = await file.length();
      int sent = 0;

      // Write form fields
      if (fields != null) {
        fields.forEach((key, value) {
          final part =
              '--$boundary\r\nContent-Disposition: form-data; name="$key"\r\n\r\n$value\r\n';
          request.write(part);
          sent += utf8.encode(part).length;
          if (onUploadProgress != null) onUploadProgress(sent, fileLength);
        });
      }

      // Write file
      final filename = file.uri.pathSegments.last;
      final mimeType = 'application/octet-stream';
      final fileHeader =
          '--$boundary\r\nContent-Disposition: form-data; name="file"; filename="$filename"\r\nContent-Type: $mimeType\r\n\r\n';
      request.write(fileHeader);
      sent += utf8.encode(fileHeader).length;

      final fileStream = file.openRead();
      await for (var chunk in fileStream) {
        if (token?.isCanceled ?? false) {
          client.close(force: true);
          onCancelCallback?.call(token!.onCancelMessage);
          throw Exception(token!.onCancelMessage);
        }
        request.add(chunk);
        await request.flush(); // ensure chunk is actually sent

        sent += chunk.length;
        if (onUploadProgress != null) onUploadProgress(sent, fileLength);
      }

      // End boundary
      final endData = '\r\n--$boundary--\r\n';
      request.write(endData);
      await request.flush();

      final response = await request.close().timeout(options.receiveTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      return TClientResponse(
        statusCode: response.statusCode,
        headers: {}, // headers convert if needed
        data: responseBody,
      );
    } catch (e) {
      TClientLogger.instance.showLog(e.toString(), tag: 'upload');
      onError?.call(e.toString());
    } finally {
      client.close();
    }
    return null;
  }

  /// Internal request handler
  Future<TClientResponse> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(
      '${options.baseUrl}$path',
    ).replace(queryParameters: query);
    // timeout
    final request = await client
        .openUrl(method, uri)
        .timeout(options.sendTimeout);
    // Default + custom headers
    final allHeaders = {...options.headers, ...?headers};
    allHeaders.forEach((key, value) => request.headers.set(key, value));

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(options.receiveTimeout);
    final responseBody = await response.transform(utf8.decoder).join();

    client.close();

    return TClientResponse(
      statusCode: response.statusCode,
      headers: {},
      data: responseBody,
    );
  }

  ///
  /// File Upload Stream
  ///
  Stream<UploadStreamProgress> uploadStream(
    String path, {
    required File file,
    TClientToken? token,
  }) {
    return httpUploadStream(this, path: path, file: file, token: token);
  }

  ///
  /// File Download Stream
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
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:t_http/t_http.dart';

typedef Interceptor =
    FutureOr<HttpResponse> Function(
      HttpClientRequest request,
      Future<HttpResponse> Function() next,
    );

typedef OnReceiveProgressCallback = void Function(int received, int total);
typedef OnReceiveProgressSpeedCallback =
    void Function(double progress, double speed, Duration? eta);
typedef OnCancelCallback = void Function(String message);

class THttp {
  final THttpOptions options;
  final HttpClient client;

  THttp({HttpClient? client, THttpOptions? options})
    : options = options ?? const THttpOptions(),
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
  Future<THttpResponse> get(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) {
    return _send('GET', path, query: query, headers: headers);
  }

  /// POST request
  Future<THttpResponse> post(
    String path, {
    Map<String, String>? query,
    Object? data,
    Map<String, String>? headers,
  }) {
    return _send('POST', path, body: data, headers: headers, query: query);
  }

  /// POST request
  Future<THttpResponse> put(
    String path, {
    Map<String, String>? query,
    Object? data,
    Map<String, String>? headers,
  }) {
    return _send('PUT', path, body: data, headers: headers, query: query);
  }

  /// POST request
  Future<THttpResponse> delete(
    String path, {
    Object? data,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) {
    return _send('DELETE', path, body: data, headers: headers, query: query);
  }

  /// File download with progress
  Future<File> download(
    String path, {
    required String savePath,
    Map<String, String>? query,
    Map<String, String>? headers,
    OnReceiveProgressCallback? onReceiveProgress,
    OnReceiveProgressSpeedCallback? onReceiveProgressSpeed,
    OnCancelCallback? onCancelCallback,
    TCancelToken? cancelToken,
    void Function(String message)? onError,
  }) async {
    final uri = Uri.parse(
      '${options.baseUrl}$path',
    ).replace(queryParameters: query);
    // timeout
    final request = await client.getUrl(uri).timeout(options.sendTimeout);

    // Default + custom headers
    final allHeaders = {...options.headers, ...?headers};
    allHeaders.forEach((key, value) => request.headers.set(key, value));

    final response = await request.close().timeout(options.receiveTimeout);
    final file = File(savePath);
    final sink = file.openWrite();

    int received = 0;
    final total = response.contentLength;
    final startTime = DateTime.now();

    try {
      await response.forEach((chunk) {
        if (cancelToken?.isCanceled ?? false) {
          sink.close();
          client.close();
          if (cancelToken!.isCancelFileDelete) {
            file.deleteSync(); // Delete partial file
          }
          onCancelCallback?.call(cancelToken.onCancelMessage);
          throw Exception(cancelToken.onCancelMessage);
        }

        received += chunk.length;
        sink.add(chunk);

        if (onReceiveProgressSpeed != null && total > 0) {
          final elapsed = DateTime.now().difference(startTime);
          final elapsedSec = elapsed.inMilliseconds / 1000.0;
          final speed = elapsedSec > 0
              ? received / elapsedSec
              : 0.0; // bytes per second
          final eta = speed > 0
              ? Duration(seconds: ((total - received) / speed).round())
              : null;
          onReceiveProgressSpeed.call(((received / total) * 100), speed, eta);
        }

        if (onReceiveProgress != null && total > 0) {
          onReceiveProgress(received, total);
        }
      });
    } catch (e) {
      onError?.call(e.toString());
    } finally {
      await sink.close();
      client.close();
    }
    return file;
  }

  /// File upload with progress
  Future<THttpResponse?> upload(
    String path, {
    required File file,
    Map<String, String>? query,
    Map<String, String>? fields, // extra form fields
    Map<String, String>? headers,
    void Function(int sent, int total)? onUploadProgress,
    OnCancelCallback? onCancelCallback,
    void Function(String message)? onError,
    TCancelToken? cancelToken,
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
        if (cancelToken?.isCanceled ?? false) {
          client.close(force: true);
          onCancelCallback?.call(cancelToken!.onCancelMessage);
          throw Exception(cancelToken!.onCancelMessage);
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

      return THttpResponse(
        statusCode: response.statusCode,
        headers: {}, // headers convert if needed
        data: responseBody,
      );
    } catch (e) {
      onError?.call(e.toString());
    } finally {
      client.close();
    }
    return null;
  }

  /// Internal request handler
  Future<THttpResponse> _send(
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

    return THttpResponse(
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
    TCancelToken? cancelToken,
  }) {
    return httpUploadStream(
      this,
      path: path,
      file: file,
      cancelToken: cancelToken,
    );
  }

  ///
  /// File Download Stream
  ///
  Stream<DownloadStreamProgress> downloadStream(
    String path, {
    required String savePath,
    TCancelToken? cancelToken,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) {
    return httpDownloadStream(
      this,
      path,
      savePath: savePath,
      cancelToken: cancelToken,
      headers: headers,
      query: query,
    );
  }
}

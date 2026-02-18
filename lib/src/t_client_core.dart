import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:t_client/src/types/method.dart';

import 'index.dart';

typedef Interceptor =
    FutureOr<HttpResponse> Function(
      HttpClientRequest request,
      Future<HttpResponse> Function() next,
    );

typedef OnReceiveProgressCallback = void Function(int received, int total);
typedef OnReceiveProgressSpeedCallback =
    void Function(int received, int total, double speed, Duration? eta);
typedef OnCancelCallback = void Function(String message);

class TClient {
  final TClientOptions options;
  final HttpClient ioClient;

  TClient({HttpClient? client, TClientOptions? options})
    : options = options ?? const TClientOptions(),
      // အပြင်က client ပေးရင် အဲဒါကိုသုံး၊ မပေးရင် အသစ်ဆောက်
      ioClient = client ?? HttpClient() {
    _configureClient();
  }

  void _configureClient() {
    ioClient.connectionTimeout = options.connectTimeout;

    // SSL Certificate စစ်ဆေးတာကို ကျော်ချင်ရင် (Development မှာပဲ သုံးသင့်တယ်)
    // ioClient.badCertificateCallback = (cert, host, port) => true;

    if (options.proxy != null) {
      ioClient.findProxy = (Uri uri) => 'PROXY ${options.proxy}';
    }
  }

  ///
  /// ### Set Client Proxy
  /// setProxy(null) => `'DIRECT'` or `No Proxy`
  ///
  void setProxy(String? proxy) {
    if (proxy == null || proxy.isEmpty) {
      ioClient.findProxy = null; // သို့မဟုတ် (uri) => 'DIRECT'
    } else {
      ioClient.findProxy = (Uri uri) => 'PROXY $proxy';
    }
  }

  ///
  /// ### build uri
  ///
  Uri buildUri(String path, Map<String, String>? query) {
    return Uri.parse('${options.baseUrl}$path').replace(queryParameters: query);
  }

  ///
  /// ### Marge Header,set All Headers
  ///
  void setHeaders(HttpClientRequest request, Map<String, dynamic>? headers) {
    final allHeaders = {...options.headers, ...?headers};
    allHeaders.forEach((key, value) => request.headers.set(key, value));
  }

  ///
  /// ### Get All Response Headers
  ///
  Map<String, String> getResponseHeaders(HttpClientResponse response) {
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name] = values.join(', ');
    });
    return responseHeaders;
  }

  ///
  /// ### sendRequest
  ///
  Future<TClientResponse> sendRequest(
    Method method,
    String path, {
    Map<String, String>? query,
    Object? body,
    Map<String, String>? headers,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) async {
    try {
      // options ထဲက default ကို သုံးမလား၊ parameter က custom ကို သုံးမလား ရွေးမယ်
      final effectiveSendTimeout = sendTimeout ?? options.sendTimeout;
      final effectiveReceiveTimeout = receiveTimeout ?? options.receiveTimeout;

      // 1. URL ကို စနစ်တကျ တည်ဆောက်ခြင်း
      Uri uri;
      if (path.startsWith('http')) {
        // Path က URL အပြည့်အစုံ ဖြစ်နေရင် အဲဒါကိုပဲ သုံးမယ်
        uri = Uri.parse(path).replace(queryParameters: query);
      } else {
        // Base URL နဲ့ Path ကို ပေါင်းစပ်မယ်
        final baseUri = Uri.parse(options.baseUrl);
        uri = baseUri.resolve(path).replace(queryParameters: query);
      }

      // 2. Request ဖွင့်ခြင်း
      final request = await ioClient
          .openUrl(method.value, uri)
          .timeout(effectiveSendTimeout); // Connect & Send Timeout

      // 3. Headers သတ်မှတ်ခြင်း
      setHeaders(request, headers);

      // JSON အတွက် Default Content-Type ထည့်ပေးခြင်း
      if (body != null && request.headers['content-type'] == null) {
        request.headers.set('content-type', 'application/json; charset=utf-8');
      }

      // 4. Body ရေးသားခြင်း
      if (body != null) {
        final bytes = utf8.encode(jsonEncode(body));
        request.contentLength = bytes.length; // Content-Length သတ်မှတ်ပေးခြင်း
        request.add(bytes);
      }

      // 5. Response ရယူခြင်း
      final response = await request.close().timeout(effectiveReceiveTimeout);
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(effectiveReceiveTimeout); // ဒီနေရာမှာပါ ထည့်သင့်ပါတယ်

      return TClientResponse(
        statusCode: response.statusCode,
        headers: getResponseHeaders(response),
        data: responseBody,
      );
    } on TimeoutException catch (e) {
      // ဘယ်နေရာက timeout ဖြစ်တာလဲဆိုတာ သိနိုင်အောင်လို့ပါ
      throw Exception(
        "Network Timeout: ${e.message ?? 'Operation took too long'}",
      );
    } on SocketException catch (e) {
      throw Exception("No Internet Connection or Server unreachable: $e");
    } catch (e) {
      throw Exception("Request failed: $e");
    }
  }
}

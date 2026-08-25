part of 't_client.dart';

sealed class IClient {
  IClient({HttpClient? httpClient, this.proxy})
    : _http = httpClient ?? HttpClient() {
    if (proxy != null) {
      _http.findProxy = (url) => 'PROXY $proxy';
    }
  }

  final HttpClient _http;

  /// proxy
  ///
  /// `host:port`
  final String? proxy;

  /// all request
  Future<HttpClientRequest> request(
    String url, {
    TMethod method = TMethod.get,
  }) async {
    final uri = Uri.parse(url);

    return switch (method) {
      TMethod.get => _http.getUrl(uri),
      TMethod.post => _http.postUrl(uri),
      TMethod.put => _http.putUrl(uri),
      TMethod.patch => _http.patchUrl(uri),
      TMethod.delete => _http.deleteUrl(uri),
      TMethod.head => _http.headUrl(uri),
    };
  }

  /// send
  ///
  /// `Object? body` -> `String`, `Map`, `List<int>`
  ///
  /// ```dart
  /// final result = await client.send(
  ///   url,
  ///   method: .post,
  ///   contentType: ContentType.json,
  ///   headers: {
  ///     'Authorization': 'Bearer $token',
  ///   },
  ///   body: {
  ///     'name': 'Than',
  ///   },
  /// );
  ///
  /// //header
  ///   headers: {
  ///   'Authorization': 'Bearer $token',
  ///   'Accept': 'application/json',
  ///   'X-Client-Version': '1.0.0',
  /// }
  /// ```
  Future<Result<HttpClientResponse, String>> send(
    String url, {
    TMethod method = TMethod.get,
    Object? body,
    ContentType? contentType,
    Map<String, String>? headers,
  }) async {
    try {
      final req = await request(url, method: method);

      if (headers != null) {
        headers.forEach(req.headers.set);
      }

      if (contentType != null) {
        req.headers.contentType = contentType;
      }

      if (body != null) {
        if (body is String) {
          req.write(body);
        } else if (body is List<int>) {
          req.add(body);
        } else {
          req.write(jsonEncode(body));
        }
      }

      return Ok(await req.close());
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// client close
  void close() {
    _http.close();
  }
}

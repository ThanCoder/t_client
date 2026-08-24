import 'dart:convert';
import 'dart:io';

import 'package:t_client/src/t_method.dart';

class TClient {
  final HttpClient _http;

  TClient({HttpClient? httpClient}) : _http = httpClient ?? HttpClient();

  Future<void> get(String url) async {
    final req = await request(url);
    final res = await req.close();

    print(res.statusCode);
    print('contentLength: ${res.contentLength}');
    final body = await res.transform(utf8.decoder).join();
    print(body);
  }

  void close() {
    _http.close();
  }

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
}

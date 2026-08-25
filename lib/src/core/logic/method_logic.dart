part of '../t_client.dart';

mixin MethodLogic on IClient {
  /// GET method
  Future<Result<ResInfo, String>> get(String url) async {
    final res = await send(url, method: .get);
    if (res.isErr) {
      return Err(res.unwrapError());
    }

    final body = await res.unwrap().transform(utf8.decoder).join('');
    return Ok(
      .new(
        response: res.unwrap(),
        statusCode: res.unwrap().statusCode,
        contentLength: res.unwrap().contentLength,
        body: body,
      ),
    );
  }

  /// POST method
  Future<Result<ResInfo, String>> post(
    String url, {
    required Map<String, dynamic> body,
    ContentType? contentType,
  }) async {
    final res = await send(url, method: .post, body: body, contentType: .json);
    if (res.isErr) {
      return Err(res.unwrapError());
    }

    final resBody = await res.unwrap().transform(utf8.decoder).join('');
    return Ok(
      .new(
        response: res.unwrap(),
        statusCode: res.unwrap().statusCode,
        contentLength: res.unwrap().contentLength,
        body: resBody,
      ),
    );
  }

  /// PUT method
  Future<Result<ResInfo, String>> put(
    String url, {
    required Map<String, dynamic> body,
    ContentType? contentType,
  }) async {
    final res = await send(url, method: .put, body: body, contentType: .json);
    if (res.isErr) {
      return Err(res.unwrapError());
    }

    final resBody = await res.unwrap().transform(utf8.decoder).join('');
    return Ok(
      .new(
        response: res.unwrap(),
        statusCode: res.unwrap().statusCode,
        contentLength: res.unwrap().contentLength,
        body: resBody,
      ),
    );
  }
}

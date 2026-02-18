import 'dart:convert';
import 'dart:io';

import 'package:t_client/src/types/method.dart';
import 'package:t_client/t_client.dart';

extension ClientStreamRequestExtensions on TClient {
  ///
  /// ### Stream Request
  ///
  Stream<TClientResponseStream> streamRequest(
    Method method,
    String path, {
    CancelToken? cancelToken,
    Map<String, String>? query,
    Object? body,
    Map<String, String>? headers,
  }) async* {
    final baseUri = Uri.parse(options.baseUrl);
    final uri = baseUri.resolve(path).replace(queryParameters: query);

    HttpClientRequest? request;

    try {
      request = await ioClient
          .openUrl(method.value, uri)
          .timeout(options.sendTimeout);

      // Headers set လုပ်ခြင်း
      final allHeaders = {...options.headers, ...?headers};
      allHeaders.forEach((k, v) => request!.headers.set(k, v));

      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(options.receiveTimeout);

      // Stream ကို Line တစ်ကြောင်းချင်းစီ ခွဲထုတ်မယ်
      final lineStream = response
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (line.trim().isEmpty) continue;

        // cancel လုပ်ရင် stream ကို stop မယ်
        if (cancelToken != null && cancelToken.isCanceled) {
          request.abort();
          break;
        }

        yield TClientResponseStream(
          data: line,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Error ဖြစ်ရင် Stream ထဲကနေ Error လွှင့်ပေးမယ်
      yield* Stream.error(e);
    } finally {
      // အကြောင်းအမျိုးမျိုးကြောင့် ရပ်သွားရင် request ကို ပိတ်မယ်
      request?.abort();
    }
  }
}

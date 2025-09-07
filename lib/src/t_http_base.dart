// ignore_for_file: public_member_api_docs, sort_constructors_first

class THttpOptions {
  final String baseUrl;
  final Map<String, String> headers;
  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;
  final String? proxy;

  const THttpOptions({
    this.baseUrl = '',
    this.headers = const {},
    this.connectTimeout = const Duration(seconds: 10),
    this.sendTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.proxy,
  });
}

class THttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final dynamic data;
  THttpResponse({
    required this.statusCode,
    required this.headers,
    required this.data,
  });
}

class TCancelToken {
  final bool isCancelFileDelete;
  final String onCancelMessage;

  bool _isCanceled = false;
  TCancelToken({
    this.isCancelFileDelete = true,
    this.onCancelMessage = 'Token Canceled',
  });

  bool get isCanceled => _isCanceled;

  void cancel() {
    _isCanceled = true;
  }
}

// stream

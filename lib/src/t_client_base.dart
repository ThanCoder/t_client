// ignore_for_file: public_member_api_docs, sort_constructors_first

class TClientOptions {
  final String baseUrl;
  final Map<String, String> headers;
  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;
  final String? proxy;

  const TClientOptions({
    this.baseUrl = '',
    this.headers = const {},
    this.connectTimeout = const Duration(seconds: 10),
    this.sendTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.proxy,
  });
}

class TClientResponse {
  final int statusCode;
  final Map<String, String> headers;
  final dynamic data;
  TClientResponse({
    required this.statusCode,
    required this.headers,
    required this.data,
  });
}

class TClientToken {
  final bool isCancelFileDelete;
  final String onCancelMessage;

  bool _isCanceled = false;
  bool _isPaused = false;

  TClientToken({
    this.isCancelFileDelete = true,
    this.onCancelMessage = 'Token Canceled',
  });

  bool get isCanceled => _isCanceled;
  bool get isPaused => _isPaused;

  void cancel() {
    _isCanceled = true;
  }

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
  }
}

// header

typedef OnTClientLoggerMessageCallback = void Function(String message);

class TClientLogger {
  static final TClientLogger instance = TClientLogger._();
  TClientLogger._();
  factory TClientLogger() => instance;

  static bool isDebugLog = true;
  OnTClientLoggerMessageCallback? onMessageLog;

  void init({OnTClientLoggerMessageCallback? onMessageLog}) {
    this.onMessageLog = onMessageLog;
  }

  void showLog(String message, {String? tag}) {
    var msg = message;
    if (tag != null) {
      msg = '[$tag]: $message';
    }
    onMessageLog?.call(msg);
  }
}

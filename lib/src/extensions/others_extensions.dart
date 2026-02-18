extension ParseDuration on Duration {
  String toAutoTimeLabel() {
    if (inMinutes > 60) {
      return '$inHours Hours';
    }
    if (inSeconds > 60) {
      return '$inMinutes Minutes';
    }
    if (inMilliseconds >= 1000) {
      return '$inSeconds S';
    }

    return '$inMilliseconds ms';
  }
}

extension DoubleExtension on double {
  String formatSpeed() {
    if (this == 0) {
      return '';
    }
    if (this >= 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
    } else if (this >= 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    } else if (this >= 1024) {
      return '${(this / 1024).toStringAsFixed(2)} KB/s';
    } else {
      return '${toStringAsFixed(0)} B/s';
    }
  }
}

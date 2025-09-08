extension DoubleExtension on double {
  String toFileSizeLabel({int asFixed = 2}) {
    String res = '';
    int pow = 1024;
    final labels = ['byte', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = this;
    while (size > pow) {
      size /= pow;
      i++;
    }

    res = '${size.toStringAsFixed(asFixed)} ${labels[i]}';

    return res;
  }

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

extension IntExtension on int {
  String toFileSizeLabel({int asFixed = 2}) {
    return toDouble().toFileSizeLabel(asFixed: asFixed);
  }
}

extension StringExtension on String {
  String toCaptalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1, length)}';
  }

  String getName({bool withExt = true}) {
    final name = split('/').last;
    if (!withExt) {
      return name.split('.').first;
    }
    return name;
  }

  String get getExt {
    return split('/').last;
  }
}

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

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

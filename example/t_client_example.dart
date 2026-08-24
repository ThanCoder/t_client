// ignore_for_file: unused_import

import 'package:t_client/t_client.dart';

void main() async {
  final t = TClient();

  await t.get("https://flutter.dev/blog");
}

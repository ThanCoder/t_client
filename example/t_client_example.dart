import 'package:t_client/t_client.dart';

void main() async {
  final client = TClient();
  final res = await client.getContentLength(
    'https://cdn.pixabay.com/photo/2015/04/19/08/32/flower-729510_1280.jpg-',
  );
  print('content: $res');
  print('statusCode: ${res.statusCode}');
  print('size: ${res.contentLength}');
}

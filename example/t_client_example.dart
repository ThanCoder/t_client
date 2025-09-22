import 'dart:io';

import 'package:t_client/src/internal.dart';
import 'package:t_client/t_client.dart';

void main() async {
  TClientLogger.instance.init(
    onMessageLog: (message) {
      print(message);
    },
  );
  final client = TClient();

  //proxy
  // final option = TClientOptions(proxy: 'http://192.168.1.1:8080');


  client.ioClient.findProxy = (uri) {
    return 'PROXY http://192.168.1.1:8080';
  };

  final fileUrl =
      'http://localhost:8080/download?path=/home/than/Videos/I.Am.What.I.Am.2021.mp4';

  //post request
  final res = await client.post('url', data: {'name': 'thancoder'});
  //200,201 - success
  res.statusCode;
  //response
  res.data;

  await client.download(
    fileUrl,
    savePath: '/home/than/Pictures/${fileUrl.getName()}',
    onError: (message) {
      print('error: $message');
    },
    onReceiveProgressSpeed: (received, total, speed, eta) {
      print(
        'Progress: ${((received / total) * 100).toStringAsFixed(2)}% | Speed: ${speed.formatSpeed()} | Left: ${eta?.toAutoTimeLabel()}',
      );
    },
  );

  // print('downloaded');

  final downloadStream = client.downloadStream(
    fileUrl,
    savePath: '/home/than/Pictures/test.mp4',
  );
  downloadStream.listen(
    (data) {
      print(
        'Progress: ${(data.receive / data.total).toStringAsFixed(2)}% | Speed: ${data.speed.formatSpeed()} | ETA: ${data.eta?.inSeconds} S',
      );
    },
    onError: (msg) {
      print('error: $msg');
    },
    onDone: () {
      print('done');
    },
  );

  // final res = await thttp.get(url);
  // print(res.data);
  // await thttp.download(
  //   'http://10.37.17.103:9000/download?path=/storage/emulated/0/Download/1DM/Videos/PERVERT%20STEPFATHER%20BREAKS%20HIS%20SKINNY%2018%20YEAR%20OLD%20STEPDAUGHTERS%20ASS%20WITHOUT%20WARNING%20AND%20SHE%20ENJOYS%20HIS%20DICK%20FROM%20BEHIND%20-%20XVIDEOS.COM.mp4',
  //   savePath: '/home/than/Pictures/test.mp4',
  //   cancelToken: TCancelToken(),
  //   onReceiveProgressSpeed: (progress, speed, eta) {
  //     final etaSec = eta?.inSeconds ?? 0;
  //     print(
  //       'Progress: ${progress.toStringAsFixed(2)}% | Speed: ${speed.formatSpeed()}| ETA: $etaSec s',
  //     );
  //   },
  // );
  final url = 'http://10.37.17.103:9000/upload';
  await client.upload(
    url,
    file: File('/home/than/Pictures/mus.mp4'),
    onUploadProgress: (sent, total) {
      print('Progress: ${(sent / total) * 100}%');
    },
  );

  final uploadStream = client.uploadStream(
    url,
    file: File('/home/than/Pictures/mus.mp4'),
  );
  uploadStream.listen(
    (data) {
      print(
        'progress: ${data.progress.toStringAsFixed(2)}% | Status: ${data.progressStatus.name}',
      );
    },
    onError: (msg) {
      print('error: $msg');
    },
    onDone: () {
      print('done');
    },
  );
}

# THttp

## Dart Core Package

## Logger

```Dart
//main
TClientLogger.instance.init(
    onMessageLog: (message) {
        print(message);
    },
);
```

## Proxy

```Dart
//option proxy
final option = TClientOptions(proxy: 'http://192.168.1.1:8080');
final client = TClient(options: option);
//set client
final client = TClient();
/*
"DIRECT"
for using a direct connection or

"PROXY host:port"
for using the proxy server host on port port.

A configuration can contain several configuration elements separated by semicolons, e.g.

"PROXY host:port; PROXY host2:port2; DIRECT"
*/
client.ioClient.findProxy = (uri) {
    return 'PROXY http://192.168.1.1:8080';
};
```

## Client Response

```Dart
final res =await client.get('url');
//respnse data
res.data;

//post request
final res =await client.post('url',data: {'name':'thancoder'});
//200,201 - success
res.statusCode;
//response
res.data;

```

## Download

```Dart
final client = TClient();
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

//Stream
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

```

## Upload

```Dart
final client = TClient();
final url = 'http://10.37.17.103:9000/upload';
await client.upload(
    url,
    file: File('/home/than/Pictures/mus.mp4'),
    onUploadProgress: (sent, total) {
        print('Progress: ${(sent / total) * 100}%');
    },
);

//Stream
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
```

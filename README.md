# TClient

## Dart Core Wrapper Package

### Stream Request

```dart
final client = TClient();
final cancelT = CancelToken();

final resStream = client.streamRequest(
    Method.post,
    'http://localhost:11434/api/generate', // Ollama local port
    body: {
        "model": "gemma3:4b",
        "prompt": "Why is the sky blue?",
        "stream": true, // ဒါက အရေးကြီးဆုံး အချက်ပါ
    },
    cancelToken: cancelT,
);

Future.delayed(Duration(seconds: 10)).then((_) {
    cancelT.cancel();
    print('call cancel');
});

await for (var res in resStream) {
    print(res.data);
    // Ollama က JSON string တွေ ပို့မှာဖြစ်လို့ decode ပြန်လုပ်ရပါမယ်
    // final decoded = jsonDecode(res.data);
    // stdout.write(
    //   decoded['response'],
    // ); // စာလုံးလေးတွေ တစ်လုံးချင်း တက်လာပါလိမ့်မယ်
}
print('stream end');
```

## THttpHeaderBuilder

```Dart
final headers = THttpHeaderBuilder();
headers.setContentType(type: HeaderContentType.applicationJson);
headers.setAccept(accept: HeaderAccept.applicationJson);
headers.setAuthorization('i am token');
headers.setUserAgent(agent: HeaderUserAgent.androidApp);
headers.setOrigin('[origin]');
headers.setCookie('[value]');
headers.setCustom('[key]', '[value]');
headers.setXApiKey('[value]');
headers.setReferer('[value]');

print(headers.getMap);
//result
/*{
    Content-Type: application/json,
    Accept: application/json,
    Authorization: i am token,
    User-Agent: MyApp/1.0.0 (Linux; Android 13),
    Origin: [origin],
    Cookie: [value],
    [key]: [value],
    X-Api-Key: [value],
    Referer: [value]
}
*/
```

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

//set proxy
  client.setProxy('[proxy url]');

//Authentication ပါတဲ့ Proxy
client.ioClient.authenticateProxy = (host, port, scheme, realm) {
    client.ioClient.addProxyCredentials(
        host,
        port,
        realm!,
        HttpClientBasicCredentials('username', 'password'),
    );
    return Future.value(true);
};

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

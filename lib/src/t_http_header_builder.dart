class THttpHeaderBuilder {
  final Map<String, dynamic> _header = {};

  // Content headers
  void setContentType({
    HeaderContentType type = HeaderContentType.applicationJson,
  }) {
    _header['Content-Type'] = type.value;
  }

  void setAccept({HeaderAccept accept = HeaderAccept.applicationJson}) {
    _header['Accept'] = accept.value;
  }

  // Auth headers
  void setAuthorization(String value) => _header['Authorization'] = value;
  void setCookie(String value) => _header['Cookie'] = value;

  // Client info
  void setUserAgent({required HeaderUserAgent agent}) {
    _header['User-Agent'] = agent.value;
  }

  void setReferer(String value) => _header['Referer'] = value;
  void setOrigin(String value) => _header['Origin'] = value;

  // Custom / API
  void setXApiKey(String value) => _header['X-Api-Key'] = value;
  void setCustom(String key, String value) => _header[key] = value;

  Map<String, dynamic> get getMap => _header;
}

enum HeaderAccept {
  applicationJson,
  textPlain,
  applicationXml;

  String get value {
    switch (this) {
      case applicationJson:
        return 'application/json';
      case textPlain:
        return 'text/plain';
      case applicationXml:
        return 'application/xml';
    }
  }
}

enum HeaderContentType {
  applicationJson,
  applicationXWwwFormUrlencoded,
  multipartFormData;

  String get value {
    switch (this) {
      case applicationJson:
        return 'application/json';
      case applicationXWwwFormUrlencoded:
        return 'application/x-www-form-urlencoded';
      case multipartFormData:
        return 'multipart/form-data';
    }
  }
}

enum HeaderUserAgent {
  chromeDesktop,
  chromeMobile,
  iOSApp,
  androidApp,
  curl;

  String get value {
    switch (this) {
      case HeaderUserAgent.chromeDesktop:
        return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';
      case HeaderUserAgent.chromeMobile:
        return 'Mozilla/5.0 (Linux; Android 13; Pixel 7 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';
      case HeaderUserAgent.iOSApp:
        return 'MyApp/1.0.0 (iPhone; iOS 17.0; Scale/3.00)';
      case HeaderUserAgent.androidApp:
        return 'MyApp/1.0.0 (Linux; Android 13)';
      case HeaderUserAgent.curl:
        return 'curl/8.2.1';
    }
  }
}

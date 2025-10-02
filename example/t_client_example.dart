import 'dart:io';

import 'package:t_client/src/internal.dart';
import 'package:t_client/t_client.dart';

void main() async {
  TClientLogger.instance.init(
    onMessageLog: (message) {
      print(message);
    },
  );
  // final client = TClient();

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
}

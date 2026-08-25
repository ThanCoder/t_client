import 'dart:convert';
import 'dart:io';

import 'package:t_client/src/core/result_t.dart';
import 'package:t_client/src/core/t_method.dart';
import 'package:t_client/src/types/downlod_res_info.dart';
import 'package:t_client/src/types/res_info.dart';

part 'i_client.dart';
part 'logic/proxy_logic.dart';
part 'logic/download_logic.dart';
part 'logic/method_logic.dart';
part 'logic/host_scanner_logic.dart';

class TClient extends IClient
    with ProxyLogic, DownloadLogic, MethodLogic, HostScannerLogic {
  TClient({super.httpClient, super.proxy});
}

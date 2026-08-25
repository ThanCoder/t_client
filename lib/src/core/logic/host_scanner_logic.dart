part of '../t_client.dart';

mixin HostScannerLogic on IClient {
  Future<Result<List<String>, String>> scanNetworkInterfaceList({
    List<String> excludePrefixes = const ['172', '127'],
  }) async {
    final result = <String>[];

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final ip in interface.addresses) {
          final address = ip.address;

          if (excludePrefixes.any(address.startsWith)) {
            continue;
          }

          result.add(address);
        }
      }

      return Ok(result);
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// await t.scanSubnet('192.168.1', 4445)
  Future<List<String>> scanSubnet(
    String subnet,
    int port, {
    Duration timeout = const Duration(milliseconds: 500),
    int concurrency = 20,
  }) async {
    final parts = subnet.split('.');

    if (parts.length == 4) {
      parts.removeLast();
      subnet = parts.join('.');
    }

    final result = <String>[];

    for (var start = 1; start <= 254; start += concurrency) {
      final end = (start + concurrency - 1).clamp(1, 254);

      final futures = [
        for (var i = start; i <= end; i++)
          _checkHost('$subnet.$i', port, timeout),
      ];

      final hosts = await Future.wait(futures);

      result.addAll(hosts.whereType<String>());
    }

    return result;
  }

  Future<String?> _checkHost(String host, int port, Duration timeout) async {
    Socket? socket;

    try {
      socket = await Socket.connect(host, port, timeout: timeout);

      return '$host:$port';
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }
}

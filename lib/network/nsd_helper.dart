import 'dart:async';
import 'dart:io';

import 'package:nsd/nsd.dart' as nsd;
import 'package:quizzapp/utils/constants.dart';

class DiscoveredHost {
  final String name;
  final String address;
  final int port;
  DiscoveredHost({required this.name, required this.address, required this.port});
}

class NsdHelper {
  NsdHelper._();
  static final NsdHelper instance = NsdHelper._();

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;

  final _ctrl = StreamController<List<DiscoveredHost>>.broadcast();
  Stream<List<DiscoveredHost>> get discoveredHosts => _ctrl.stream;

  List<DiscoveredHost> get currentHosts {
    if (_discovery == null) return [];
    return _discovery!.services
        .where((s) => s.addresses != null && s.addresses!.isNotEmpty)
        .map((s) => DiscoveredHost(
              name: s.name ?? 'Unknown',
              address: s.addresses!.first.address,
              port: s.port ?? kHostPort,
            ))
        .toList();
  }

  Future<void> startAdvertising(String hostName, int pin) async {
    try {
      _registration = await nsd.register(nsd.Service(
        name: '$hostName-$pin',
        type: kServiceType,
        port: kHostPort,
      ));
    } catch (_) {}
  }

  Future<void> startDiscovery() async {
    try {
      _discovery = await nsd.startDiscovery(kServiceType);
      _discovery!.addListener(_onServicesChanged);
    } catch (_) {}
  }

  void _onServicesChanged() {
    _ctrl.add(currentHosts);
  }

  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> stopAll() async {
    _discovery?.removeListener(_onServicesChanged);
    if (_discovery != null) {
      try { await nsd.stopDiscovery(_discovery!); } catch (_) {}
      _discovery = null;
    }
    if (_registration != null) {
      try { await nsd.unregister(_registration!); } catch (_) {}
      _registration = null;
    }
  }
}

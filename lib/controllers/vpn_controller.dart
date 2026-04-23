import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/packet.dart';

const vpn = MethodChannel('vpn_channel');
const packetChannel = EventChannel('packet_channel');

class VpnController with ChangeNotifier {
  String _vpnStatus = 'VPN not started';
  final List<Packet> _packets = [];
  String _filterProtocol = 'All';
  String _filterSource = '';
  String _filterDest = '';
  String _filterPort = '';
  String _filterSourceHost = '';
  String _filterDestHost = '';
  String _filterDirection = 'All';

  // VPN Configuration
  int _bufferSize = 32767;
  String _vpnAddress = '10.0.0.2';
  int _vpnPrefixLength = 32;
  String _dnsServer = '8.8.8.8';
  String _routeAddress = '0.0.0.0';
  int _routePrefixLength = 0;
  String _sessionName = 'FlutterVPN';

  String get vpnStatus => _vpnStatus;
  List<Packet> get packets => _packets;
  String get filterProtocol => _filterProtocol;
  String get filterSource => _filterSource;
  String get filterDest => _filterDest;
  String get filterPort => _filterPort;
  String get filterSourceHost => _filterSourceHost;
  String get filterDestHost => _filterDestHost;
  String get filterDirection => _filterDirection;

  // VPN Configuration Getters
  int get bufferSize => _bufferSize;
  String get vpnAddress => _vpnAddress;
  int get vpnPrefixLength => _vpnPrefixLength;
  String get dnsServer => _dnsServer;
  String get routeAddress => _routeAddress;
  int get routePrefixLength => _routePrefixLength;
  String get sessionName => _sessionName;

  List<Packet> get filteredPackets {
    return _packets.where((p) {
      final protocolMatch =
          _filterProtocol == 'All' || p.protocolName == _filterProtocol;
      final sourceMatch =
          _filterSource.isEmpty || p.source.contains(_filterSource);
      final destMatch =
          _filterDest.isEmpty || p.destination.contains(_filterDest);
      final portMatch =
          _filterPort.isEmpty ||
          (p.sourcePort?.toString().contains(_filterPort) ?? false) ||
          (p.destPort?.toString().contains(_filterPort) ?? false);
      final sourceHostMatch =
          _filterSourceHost.isEmpty ||
          (p.sourceHost?.contains(_filterSourceHost) ?? false);
      final destHostMatch =
          _filterDestHost.isEmpty ||
          (p.destHost?.contains(_filterDestHost) ?? false);
      final directionMatch =
          _filterDirection == 'All' ||
          (_filterDirection == 'IN' && p.isIncoming) ||
          (_filterDirection == 'OUT' && p.isOutgoing) ||
          (_filterDirection == 'UNK' && !p.isIncoming && !p.isOutgoing);
      return protocolMatch &&
          sourceMatch &&
          destMatch &&
          portMatch &&
          sourceHostMatch &&
          destHostMatch &&
          directionMatch;
    }).toList();
  }

  int get totalPackets => _packets.length;
  int get inPackets => _packets.where((p) => p.direction == 'IN').length;
  int get outPackets => _packets.where((p) => p.direction == 'OUT').length;
  int get totalBytes => _packets.fold(0, (sum, p) => sum + p.length);

  VpnController() {
    packetChannel.receiveBroadcastStream().listen((event) {
      debugPrint("Received packet: $event");
      _packets.add(Packet.fromMap(Map<String, dynamic>.from(event)));
      notifyListeners();
    });
  }

  Future<void> startVpn() async {
    try {
      await vpn.invokeMethod('startVpn', {
        'bufferSize': _bufferSize,
        'vpnAddress': _vpnAddress,
        'vpnPrefixLength': _vpnPrefixLength,
        'dnsServer': _dnsServer,
        'routeAddress': _routeAddress,
        'routePrefixLength': _routePrefixLength,
        'sessionName': _sessionName,
      });
      _vpnStatus = 'VPN started';
      _packets.clear();
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint("Failed to start VPN: '${e.message}'.");
    }
  }

  Future<void> stopVpn() async {
    try {
      await vpn.invokeMethod('stopVpn');
      _vpnStatus = 'VPN stopped';
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint("Failed to stop VPN: '${e.message}'.");
    }
  }

  Future<void> testTraffic() async {
    try {
      await vpn.invokeMethod('testTraffic');
    } catch (e) {
      debugPrint('Error testing traffic: $e');
    }
  }

  void clearPackets() {
    _packets.clear();
    notifyListeners();
  }

  void setFilterProtocol(String value) {
    _filterProtocol = value;
    notifyListeners();
  }

  void setFilterSource(String value) {
    _filterSource = value;
    notifyListeners();
  }

  void setFilterDest(String value) {
    _filterDest = value;
    notifyListeners();
  }

  void setFilterPort(String value) {
    _filterPort = value;
    notifyListeners();
  }

  void setFilterSourceHost(String value) {
    _filterSourceHost = value;
    notifyListeners();
  }

  void setFilterDestHost(String value) {
    _filterDestHost = value;
    notifyListeners();
  }

  void setFilterDirection(String value) {
    _filterDirection = value;
    notifyListeners();
  }

  // VPN Configuration Setters
  void setBufferSize(int value) {
    _bufferSize = value;
    notifyListeners();
  }

  void setVpnAddress(String value) {
    _vpnAddress = value;
    notifyListeners();
  }

  void setVpnPrefixLength(int value) {
    _vpnPrefixLength = value;
    notifyListeners();
  }

  void setDnsServer(String value) {
    _dnsServer = value;
    notifyListeners();
  }

  void setRouteAddress(String value) {
    _routeAddress = value;
    notifyListeners();
  }

  void setRoutePrefixLength(int value) {
    _routePrefixLength = value;
    notifyListeners();
  }

  void setSessionName(String value) {
    _sessionName = value;
    notifyListeners();
  }
}

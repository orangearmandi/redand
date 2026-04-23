import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkInfoView extends StatefulWidget {
  const NetworkInfoView({super.key});

  @override
  State<NetworkInfoView> createState() => _NetworkInfoViewState();
}

class _NetworkInfoViewState extends State<NetworkInfoView> {
  final NetworkInfo _networkInfo = NetworkInfo();
  Map<String, String?> _networkInfoData = {};

  @override
  void initState() {
    super.initState();
    _getNetworkInfo();
  }

  Future<void> _getNetworkInfo() async {
    try {
      final wifiName = await _networkInfo.getWifiName();
      final wifiBSSID = await _networkInfo.getWifiBSSID();
      final wifiIP = await _networkInfo.getWifiIP();
      final wifiIPv6 = await _networkInfo.getWifiIPv6();
      final wifiSubmask = await _networkInfo.getWifiSubmask();
      final wifiBroadcast = await _networkInfo.getWifiBroadcast();
      final wifiGateway = await _networkInfo.getWifiGatewayIP();

      setState(() {
        _networkInfoData = {
          'WiFi Name': wifiName,
          'WiFi BSSID': wifiBSSID,
          'WiFi IP': wifiIP,
          'WiFi IPv6': wifiIPv6,
          'WiFi Subnet Mask': wifiSubmask,
          'WiFi Broadcast': wifiBroadcast,
          'WiFi Gateway': wifiGateway,
        };
      });
    } catch (e) {
      setState(() {
        _networkInfoData = {'Error': e.toString()};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Information'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getNetworkInfo,
            tooltip: 'Refresh Network Info',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Network Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: _networkInfoData.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${entry.key}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              entry.value ?? 'Not available',
                              style: TextStyle(
                                fontSize: 16,
                                color: entry.value == null
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'About Network Info Plus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'This view uses the network_info_plus package to retrieve information about the current network connection, including WiFi details, IP addresses, subnet masks, and gateway information.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

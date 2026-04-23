import 'dart:async';
import 'package:flutter/material.dart';

class UpnpView extends StatefulWidget {
  const UpnpView({super.key});

  @override
  State<UpnpView> createState() => _UpnpViewState();
}

class _UpnpViewState extends State<UpnpView> {
  final List<dynamic> _discoveredDevices = [];
  bool _isDiscovering = false;
  String _status = 'Ready to discover UPnP devices';

  @override
  void dispose() {
    _stopDiscovery();
    super.dispose();
  }

  void _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _discoveredDevices.clear();
      _status = 'Discovering UPnP devices...';
    });

    try {
      // For now, just simulate discovery since upnp_client API might be different
      // This is a placeholder implementation
      await Future.delayed(const Duration(seconds: 3));

      setState(() {
        _isDiscovering = false;
        _status =
            'Discovery completed. UPnP client integration needs API verification.';
        _discoveredDevices.add({
          'name': 'UPnP Device Discovery',
          'description':
              'This feature requires proper UPnP client API integration',
          'type': 'Placeholder',
        });
      });
    } catch (e) {
      setState(() {
        _isDiscovering = false;
        _status = 'Error during discovery: $e';
      });
    }
  }

  void _stopDiscovery() {
    setState(() {
      _isDiscovering = false;
      _status = 'Discovery stopped';
    });
  }

  void _showDeviceDetails(dynamic device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device['name'] ?? 'Device Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', device['description']),
              _buildDetailRow('Type', device['type']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value ?? 'Not available')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPnP Device Discovery'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discover UPnP Devices',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDiscovering
                        ? _stopDiscovery
                        : _startDiscovery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDiscovering
                          ? Colors.red
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isDiscovering ? 'Stop Discovery' : 'Start Discovery',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                color: _isDiscovering ? Colors.blue : Colors.black,
                fontWeight: _isDiscovering
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discovered UPnP Devices:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _discoveredDevices.isEmpty
                            ? const Center(
                                child: Text(
                                  'No UPnP devices discovered yet.\nTry discovering devices on your local network.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _discoveredDevices.length,
                                itemBuilder: (context, index) {
                                  final device = _discoveredDevices[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        device['name'] ??
                                            device['description'] ??
                                            'Unknown Device',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Type: ${device['type'] ?? 'Unknown'}',
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.info_outline),
                                        onPressed: () =>
                                            _showDeviceDetails(device),
                                      ),
                                      onTap: () => _showDeviceDetails(device),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'About UPnP Client',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This view is a placeholder for UPnP device discovery. The upnp_client package integration requires proper API verification and implementation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

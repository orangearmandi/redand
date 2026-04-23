import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';

class MulticastDnsView extends StatefulWidget {
  const MulticastDnsView({super.key});

  @override
  State<MulticastDnsView> createState() => _MulticastDnsViewState();
}

class _MulticastDnsViewState extends State<MulticastDnsView> {
  final TextEditingController _serviceController = TextEditingController(
    text: '_http._tcp',
  );
  MDnsClient? _client;
  final List<ResourceRecord> _discoveredServices = [];
  bool _isDiscovering = false;
  String _status = 'Ready to discover services';

  @override
  void dispose() {
    _serviceController.dispose();
    _stopDiscovery();
    super.dispose();
  }

  void _startDiscovery() async {
    final serviceType = _serviceController.text.trim();
    if (serviceType.isEmpty) {
      setState(() {
        _status = 'Please enter a service type';
      });
      return;
    }

    setState(() {
      _isDiscovering = true;
      _discoveredServices.clear();
      _status = 'Discovering $serviceType services...';
    });

    try {
      _client = MDnsClient();
      await _client!.start();

      await for (final ResourceRecord record
          in _client!.lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(serviceType),
          )) {
        if (!mounted) break;

        setState(() {
          _discoveredServices.add(record);
        });

        // Also lookup SRV records for more details
        if (record is PtrResourceRecord) {
          final srvRecords = await _client!
              .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(record.domainName),
              )
              .toList();

          final txtRecords = await _client!
              .lookup<TxtResourceRecord>(
                ResourceRecordQuery.text(record.domainName),
              )
              .toList();

          setState(() {
            _discoveredServices.addAll(srvRecords);
            _discoveredServices.addAll(txtRecords);
          });
        }
      }

      setState(() {
        _isDiscovering = false;
        _status =
            'Discovery completed. Found ${_discoveredServices.length} records.';
      });
    } catch (e) {
      setState(() {
        _isDiscovering = false;
        _status = 'Error during discovery: $e';
      });
    }
  }

  void _stopDiscovery() {
    _client?.stop();
    setState(() {
      _isDiscovering = false;
      _status = 'Discovery stopped';
    });
  }

  String _formatRecord(ResourceRecord record) {
    if (record is PtrResourceRecord) {
      return 'PTR: ${record.domainName}';
    } else if (record is SrvResourceRecord) {
      return 'SRV: ${record.name} -> ${record.target}:${record.port}';
    } else if (record is TxtResourceRecord) {
      return 'TXT: ${record.name} -> ${record.text}';
    } else {
      return '${record.resourceRecordType}: ${record.name}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multicast DNS Discovery'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discover Network Services',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _serviceController,
                    decoration: const InputDecoration(
                      labelText: 'Service Type',
                      hintText: 'e.g., _http._tcp, _printer._tcp',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _startDiscovery(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isDiscovering ? _stopDiscovery : _startDiscovery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDiscovering ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isDiscovering ? 'Stop' : 'Discover'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Common service types: _http._tcp, _printer._tcp, _ipp._tcp, _afpovertcp._tcp',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                        'Discovered Records:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _discoveredServices.isEmpty
                            ? const Center(
                                child: Text(
                                  'No services discovered yet.\nTry discovering services on your local network.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _discoveredServices.length,
                                itemBuilder: (context, index) {
                                  final record = _discoveredServices[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatRecord(record),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
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
              'About Multicast DNS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This view uses the multicast_dns package to discover services on the local network using mDNS (Multicast DNS) protocol, commonly used for service discovery in local networks.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

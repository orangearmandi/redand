import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart';

class PingView extends StatefulWidget {
  const PingView({super.key});

  @override
  State<PingView> createState() => _PingViewState();
}

class _PingViewState extends State<PingView> {
  final TextEditingController _hostController = TextEditingController(
    text: '8.8.8.8',
  );
  Ping? _ping;
  StreamSubscription<PingData>? _subscription;
  final List<PingData> _pingResults = [];
  bool _isPinging = false;
  String _status = 'Ready to ping';

  @override
  void dispose() {
    _hostController.dispose();
    _stopPing();
    super.dispose();
  }

  void _startPing() {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      setState(() {
        _status = 'Please enter a host or IP address';
      });
      return;
    }

    setState(() {
      _isPinging = true;
      _pingResults.clear();
      _status = 'Pinging $host...';
    });

    _ping = Ping(host, count: 10, timeout: 2, interval: 1);
    _subscription = _ping!.stream.listen(
      (pingData) {
        setState(() {
          _pingResults.add(pingData);
        });
      },
      onDone: () {
        setState(() {
          _isPinging = false;
          _status = 'Ping completed';
        });
      },
      onError: (error) {
        setState(() {
          _isPinging = false;
          _status = 'Error: $error';
        });
      },
    );
  }

  void _stopPing() {
    _subscription?.cancel();
    _ping?.stop();
    setState(() {
      _isPinging = false;
      _status = 'Ping stopped';
    });
  }

  String _formatPingData(PingData data) {
    if (data.response != null) {
      final response = data.response!;
      if (response.ttl != null && response.time != null) {
        return 'Reply from ${response.ip}: time=${response.time!.inMilliseconds}ms TTL=${response.ttl}';
      } else if (response.time != null) {
        return 'Reply from ${response.ip}: time=${response.time!.inMilliseconds}ms';
      } else {
        return 'Reply from ${response.ip}';
      }
    } else if (data.error != null) {
      return 'Request timeout or error: ${data.error}';
    } else {
      return 'Unknown response';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Ping'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ping Host or IP Address',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host or IP Address',
                      hintText: 'e.g., 8.8.8.8 or google.com',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _startPing(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isPinging ? _stopPing : _startPing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPinging ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isPinging ? 'Stop' : 'Ping'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                color: _isPinging ? Colors.blue : Colors.black,
                fontWeight: _isPinging ? FontWeight.bold : FontWeight.normal,
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
                        'Ping Results:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _pingResults.length,
                          itemBuilder: (context, index) {
                            final data = _pingResults[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1}. ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _formatPingData(data),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: data.response != null
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
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
              'About Dart Ping',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This view uses the dart_ping package to send ICMP echo requests to test network connectivity and measure response times.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

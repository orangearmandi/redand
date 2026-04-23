import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class SocketConnectView extends StatefulWidget {
  const SocketConnectView({super.key});

  @override
  State<SocketConnectView> createState() => _SocketConnectViewState();
}

class _SocketConnectViewState extends State<SocketConnectView> {
  final TextEditingController _hostController = TextEditingController(
    text: '8.8.8.8',
  );
  final TextEditingController _portController = TextEditingController(
    text: '53',
  );
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Socket? _tcpSocket;
  RawDatagramSocket? _udpSocket;
  bool _isTcpConnected = false;
  bool _isUdpBound = false;
  String _connectionStatus = 'Disconnected';
  final List<String> _messages = [];
  String _selectedProtocol = 'TCP';

  final List<String> _protocols = ['TCP', 'UDP'];

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _disconnect();
    super.dispose();
  }

  void _addMessage(String message) {
    setState(() {
      _messages.add('[${DateTime.now().toString().split('.').first}] $message');
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _connect() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());

    if (host.isEmpty || port == null) {
      _addMessage('Error: Please enter valid host and port');
      return;
    }

    try {
      if (_selectedProtocol == 'TCP') {
        await _connectTcp(host, port);
      } else {
        await _connectUdp(host, port);
      }
    } catch (e) {
      _addMessage('Connection error: $e');
      setState(() {
        _connectionStatus = 'Connection failed';
      });
    }
  }

  Future<void> _connectTcp(String host, int port) async {
    setState(() {
      _connectionStatus = 'Connecting to $host:$port (TCP)...';
    });

    _tcpSocket = await Socket.connect(host, port);
    setState(() {
      _isTcpConnected = true;
      _connectionStatus = 'Connected to $host:$port (TCP)';
    });

    _addMessage('TCP connection established to $host:$port');

    _tcpSocket!.listen(
      (data) {
        final message = utf8.decode(data);
        _addMessage('Received: $message');
      },
      onError: (error) {
        _addMessage('TCP Error: $error');
        _disconnect();
      },
      onDone: () {
        _addMessage('TCP connection closed by server');
        _disconnect();
      },
    );
  }

  Future<void> _connectUdp(String host, int port) async {
    setState(() {
      _connectionStatus = 'Binding UDP socket...';
    });

    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    setState(() {
      _isUdpBound = true;
      _connectionStatus = 'UDP socket bound (local port: ${_udpSocket!.port})';
    });

    _addMessage('UDP socket bound to port ${_udpSocket!.port}');

    _udpSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _udpSocket!.receive();
        if (datagram != null) {
          final message = utf8.decode(datagram.data);
          _addMessage(
            'Received from ${datagram.address}:${datagram.port}: $message',
          );
        }
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      if (_selectedProtocol == 'TCP' && _isTcpConnected) {
        _tcpSocket!.write(message);
        _addMessage('Sent (TCP): $message');
      } else if (_selectedProtocol == 'UDP' && _isUdpBound) {
        final host = _hostController.text.trim();
        final port = int.tryParse(_portController.text.trim()) ?? 0;
        final data = utf8.encode(message);
        _udpSocket!.send(data, InternetAddress(host), port);
        _addMessage('Sent (UDP) to $host:$port: $message');
      } else {
        _addMessage('Error: Not connected');
      }
    } catch (e) {
      _addMessage('Send error: $e');
    }

    _messageController.clear();
  }

  void _disconnect() {
    if (_tcpSocket != null) {
      _tcpSocket!.destroy();
      _tcpSocket = null;
      _addMessage('TCP connection closed');
    }

    if (_udpSocket != null) {
      _udpSocket!.close();
      _udpSocket = null;
      _addMessage('UDP socket closed');
    }

    setState(() {
      _isTcpConnected = false;
      _isUdpBound = false;
      _connectionStatus = 'Disconnected';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isConnected =
        (_selectedProtocol == 'TCP' && _isTcpConnected) ||
        (_selectedProtocol == 'UDP' && _isUdpBound);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket Connection Test'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Socket Connections',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Protocol Selection
            Row(
              children: [
                const Text('Protocol: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedProtocol,
                  items: _protocols.map((protocol) {
                    return DropdownMenuItem(
                      value: protocol,
                      child: Text(protocol),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _disconnect();
                      setState(() {
                        _selectedProtocol = value;
                        _messages.clear();
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Connection Controls
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host/IP',
                      hintText: 'e.g., 8.8.8.8',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: 'e.g., 53',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isConnected ? _disconnect : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isConnected ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              _connectionStatus,
              style: TextStyle(
                fontSize: 14,
                color: isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Message Input (only show when connected)
            if (isConnected) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Message to send (${_selectedProtocol})',
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    child: const Text('Send'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Messages Log
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connection Log:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _messages.isEmpty
                            ? const Center(
                                child: Text(
                                  'No messages yet.\nConnect to a socket to start testing.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2.0,
                                    ),
                                    child: Text(
                                      _messages[index],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
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
              'About Socket Connection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This view uses Dart\'s built-in Socket.connect for TCP connections and RawDatagramSocket for UDP to test network connectivity and send/receive data to network services.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

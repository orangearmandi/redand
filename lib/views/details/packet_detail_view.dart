import 'package:flutter/material.dart';
import 'package:redand/models/packet.dart';

class PacketDetailView extends StatefulWidget {
  final Packet packet;

  const PacketDetailView({super.key, required this.packet});

  @override
  State<PacketDetailView> createState() => _PacketDetailViewState();
}

class _PacketDetailViewState extends State<PacketDetailView> {
  String _selectedFormat = 'both'; // 'hex', 'text', 'both'

  String _getFormattedPayload() {
    if (widget.packet.payload == null || widget.packet.payload!.isEmpty) {
      return 'No payload data';
    }

    // Convert hex string to bytes
    final hexString = widget.packet.payload!.replaceAll(' ', '');
    final bytes = <int>[];
    for (int i = 0; i < hexString.length; i += 2) {
      final byteString = hexString.substring(i, i + 2);
      bytes.add(int.parse(byteString, radix: 16));
    }

    String result = '';

    switch (_selectedFormat) {
      case 'hex':
        // Format hex with spaces every 2 bytes
        result = widget.packet.payload!;
        break;
      case 'text':
        // Try to decode as UTF-8 text
        String textRepresentation = '';
        try {
          textRepresentation = String.fromCharCodes(
            bytes.where((b) => b >= 32 && b <= 126),
          );
          if (textRepresentation.length > 50) {
            textRepresentation = '${textRepresentation.substring(0, 50)}...';
          }
        } catch (e) {
          textRepresentation = 'Binary data';
        }
        result = textRepresentation;
        break;
      case 'both':
      default:
        // Try to decode as UTF-8 text
        String textRepresentation = '';
        try {
          textRepresentation = String.fromCharCodes(
            bytes.where((b) => b >= 32 && b <= 126),
          );
          if (textRepresentation.length > 50) {
            textRepresentation = '${textRepresentation.substring(0, 50)}...';
          }
        } catch (e) {
          textRepresentation = 'Binary data';
        }

        result = 'Hex: ${widget.packet.payload}\nText: $textRepresentation';
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Packet Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'From: ${widget.packet.displaySource}${widget.packet.sourcePort != null ? ':${widget.packet.sourcePort}' : ''}',
                    ),
                    Text(
                      'To: ${widget.packet.displayDest}${widget.packet.destPort != null ? ':${widget.packet.destPort}' : ''}',
                    ),
                    Text('Protocol: ${widget.packet.protocolName}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IP Header',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text('Version: ${widget.packet.version}'),
                    Text('Header Length: ${widget.packet.ihl}'),
                    Text('TOS: ${widget.packet.tos}'),
                    Text('Total Length: ${widget.packet.totalLength}'),
                    Text('ID: ${widget.packet.id}'),
                    Text('Flags: ${widget.packet.flags}'),
                    Text('Fragment Offset: ${widget.packet.fragmentOffset}'),
                    Text('TTL: ${widget.packet.ttl}'),
                    Text('Checksum: ${widget.packet.checksum}'),
                    if (widget.packet.sourceHost?.isNotEmpty == true)
                      Text('Source Host: ${widget.packet.sourceHost}'),
                    if (widget.packet.destHost?.isNotEmpty == true)
                      Text('Dest Host: ${widget.packet.destHost}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.packet.protocol == 6) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TCP Header',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text('Sequence: ${widget.packet.seq}'),
                      Text('Acknowledgment: ${widget.packet.ack}'),
                      Text('Flags: ${widget.packet.tcpFlags}'),
                      Text('Window: ${widget.packet.window}'),
                    ],
                  ),
                ),
              ),
            ] else if (widget.packet.protocol == 17) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UDP Header',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text('Length: ${widget.packet.udpLength}'),
                    ],
                  ),
                ),
              ),
            ] else if (widget.packet.protocol == 1) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ICMP Header',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text('Type: ${widget.packet.icmpType}'),
                      Text('Code: ${widget.packet.icmpCode}'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Payload',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (widget.packet.hasMorePayload == true)
                          const Text(
                            ' (truncated)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Format selector
                    Row(
                      children: [
                        const Text(
                          'Format: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedFormat,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'hex',
                                child: Text('Hexadecimal'),
                              ),
                              DropdownMenuItem(
                                value: 'text',
                                child: Text('Text'),
                              ),
                              DropdownMenuItem(
                                value: 'both',
                                child: Text('Hex + Text'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedFormat = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        _getFormattedPayload(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (widget.packet.payloadLength != null &&
                        widget.packet.payloadLength! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Total Payload Size: ${widget.packet.payloadLength} bytes',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

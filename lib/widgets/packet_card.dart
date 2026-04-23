import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/packet.dart';
import '../views/packet_detail_view.dart';

class PacketCard extends StatelessWidget {
  final Packet packet;

  const PacketCard({super.key, required this.packet});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: packet.directionColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: packet.directionColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          '${packet.displaySource}${packet.sourcePort != null ? ':${packet.sourcePort}' : ''} -> ${packet.displayDest}${packet.destPort != null ? ':${packet.destPort}' : ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(
              packet.direction,
              style: TextStyle(
                color: packet.directionColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${packet.protocolName} | Length: ${packet.length} | TTL: ${packet.ttl}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (packet.payload != null && packet.payload!.isNotEmpty)
              const Icon(Icons.data_usage, size: 16, color: Colors.purple),
            const SizedBox(width: 4),
            Text(
              DateFormat(
                'HH:mm:ss',
              ).format(DateTime.fromMillisecondsSinceEpoch(packet.timestamp)),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PacketDetailView(packet: packet),
                  ),
                );
              },
              tooltip: 'View Details',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IP Version: ${packet.version}'),
                Text('Header Length: ${packet.ihl}'),
                Text('TOS: ${packet.tos}'),
                Text('Total Length: ${packet.totalLength}'),
                Text('ID: ${packet.id}'),
                Text('Flags: ${packet.flags}'),
                Text('Fragment Offset: ${packet.fragmentOffset}'),
                Text('TTL: ${packet.ttl}'),
                Text('Checksum: ${packet.checksum}'),
                if (packet.sourceHost?.isNotEmpty == true)
                  Text('Source Host: ${packet.sourceHost}'),
                if (packet.destHost?.isNotEmpty == true)
                  Text('Dest Host: ${packet.destHost}'),
                if (packet.protocol == 6) ...[
                  Text('TCP Seq: ${packet.seq}'),
                  Text('TCP Ack: ${packet.ack}'),
                  Text('TCP Flags: ${packet.tcpFlags}'),
                  Text('TCP Window: ${packet.window}'),
                ] else if (packet.protocol == 17) ...[
                  Text('UDP Length: ${packet.udpLength}'),
                ] else if (packet.protocol == 1) ...[
                  Text('ICMP Type: ${packet.icmpType}'),
                  Text('ICMP Code: ${packet.icmpCode}'),
                ],
                if (packet.payload != null && packet.payload!.isNotEmpty)
                  Text('Payload: ${packet.payload!.length} bytes'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

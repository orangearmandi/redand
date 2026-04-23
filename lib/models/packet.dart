import 'package:flutter/material.dart';

class Packet {
  final int version;
  final int ihl;
  final int tos;
  final int totalLength;
  final int id;
  final int flags;
  final int fragmentOffset;
  final int ttl;
  final int protocol;
  final int checksum;
  final String source;
  final String destination;
  final int length;
  final int timestamp;
  final String? sourceHost;
  final String? destHost;
  final int? sourcePort;
  final int? destPort;
  final int? seq;
  final int? ack;
  final String? tcpFlags;
  final int? window;
  final int? udpLength;
  final int? icmpType;
  final int? icmpCode;
  final String? payload;
  final int? payloadLength;
  final bool? hasMorePayload;

  Packet({
    required this.version,
    required this.ihl,
    required this.tos,
    required this.totalLength,
    required this.id,
    required this.flags,
    required this.fragmentOffset,
    required this.ttl,
    required this.protocol,
    required this.checksum,
    required this.source,
    required this.destination,
    required this.length,
    required this.timestamp,
    this.sourceHost,
    this.destHost,
    this.sourcePort,
    this.destPort,
    this.seq,
    this.ack,
    this.tcpFlags,
    this.window,
    this.udpLength,
    this.icmpType,
    this.icmpCode,
    this.payload,
    this.payloadLength,
    this.hasMorePayload,
  });

  factory Packet.fromMap(Map<String, dynamic> map) {
    return Packet(
      version: map['version'] ?? 0,
      ihl: map['ihl'] ?? 0,
      tos: map['tos'] ?? 0,
      totalLength: map['totalLength'] ?? 0,
      id: map['id'] ?? 0,
      flags: map['flags'] ?? 0,
      fragmentOffset: map['fragmentOffset'] ?? 0,
      ttl: map['ttl'] ?? 0,
      protocol: map['protocol'] ?? 0,
      checksum: map['checksum'] ?? 0,
      source: map['source'] ?? '',
      destination: map['destination'] ?? '',
      length: map['length'] ?? 0,
      timestamp: map['timestamp'] ?? 0,
      sourceHost: map['sourceHost'],
      destHost: map['destHost'],
      sourcePort: map['sourcePort'],
      destPort: map['destPort'],
      seq: map['seq'],
      ack: map['ack'],
      tcpFlags: map['tcpFlags'],
      window: map['window'],
      udpLength: map['udpLength'],
      icmpType: map['icmpType'],
      icmpCode: map['icmpCode'],
      payload: map['payload'],
      payloadLength: map['payloadLength'],
      hasMorePayload: map['hasMorePayload'],
    );
  }

  String get protocolName {
    switch (protocol) {
      case 1:
        return 'ICMP';
      case 6:
        return 'TCP';
      case 17:
        return 'UDP';
      default:
        return 'Unknown ($protocol)';
    }
  }

  String get displaySource =>
      sourceHost?.isNotEmpty == true ? sourceHost! : source;
  String get displayDest =>
      destHost?.isNotEmpty == true ? destHost! : destination;

  bool get isIncoming => destination == '10.0.0.2';
  bool get isOutgoing => source == '10.0.0.2';

  String get direction => isIncoming
      ? 'IN'
      : isOutgoing
      ? 'OUT'
      : 'UNK';

  Color get directionColor => isIncoming
      ? Colors.green
      : isOutgoing
      ? Colors.blue
      : Colors.grey;

  String get formattedPayload {
    if (payload == null || payload!.isEmpty) return 'No payload';

    // Convert hex string to bytes for text analysis
    final bytes = <int>[];
    for (int i = 0; i < payload!.length; i += 2) {
      final hex = payload!.substring(i, i + 2);
      bytes.add(int.parse(hex, radix: 16));
    }

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

    // Format hex with spaces every 2 bytes
    final hexFormatted = payload!.replaceAllMapped(
      RegExp(r'.{2}'),
      (match) => '${match.group(0)} ',
    );

    return 'Hex: ${hexFormatted.trim()}\nText: $textRepresentation';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:redand/controllers/vpn_controller.dart';
import 'package:redand/widgets/packet_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<VpnController>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('VPN Packet Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: controller.clearPackets,
            tooltip: 'Clear Packets',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'VPN Monitor Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_red_eye),
              title: const Text('Simple View (No Filters)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/simple');
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Network Tools',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.wifi),
              title: const Text('Network Info'),
              subtitle: const Text('View current network information'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/network_info');
              },
            ),
            ListTile(
              leading: const Icon(Icons.network_ping),
              title: const Text('Ping Test'),
              subtitle: const Text('Test connectivity to hosts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/ping');
              },
            ),
            ListTile(
              leading: const Icon(Icons.dns),
              title: const Text('Multicast DNS'),
              subtitle: const Text('Discover mDNS services'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/multicast_dns');
              },
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('UPnP Discovery'),
              subtitle: const Text('Find UPnP devices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/upnp');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cable),
              title: const Text('Socket Test'),
              subtitle: const Text('Test TCP/UDP connections'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/socket_connect');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                // Navigate to about
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide =
              constraints.maxWidth > 600; // Tablet/Desktop breakpoint
          final padding = isWide ? 24.0 : 16.0;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        children: [
                          Text(
                            'VPN Status: ${controller.vpnStatus}',
                            style: TextStyle(
                              fontSize: isWide ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (isWide)
                            // Desktop/Tablet: Grid layout for buttons
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 3,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                ElevatedButton.icon(
                                  onPressed: controller.startVpn,
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Start VPN'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: controller.stopVpn,
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Stop VPN'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: controller.testTraffic,
                                  icon: const Icon(Icons.network_check),
                                  label: const Text('Test Traffic'),
                                ),
                              ],
                            )
                          else
                            // Mobile: Horizontal scroll
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: controller.startVpn,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Start VPN'),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: controller.stopVpn,
                                    icon: const Icon(Icons.stop),
                                    label: const Text('Stop VPN'),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: controller.testTraffic,
                                    icon: const Icon(Icons.network_check),
                                    label: const Text('Test Traffic'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Statistics Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        children: [
                          Text(
                            'Packet Statistics',
                            style: TextStyle(
                              fontSize: isWide ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (isWide)
                            // Desktop: Row layout
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(
                                  'Total',
                                  controller.totalPackets.toString(),
                                  Icons.data_usage,
                                ),
                                _buildStatItem(
                                  'IN',
                                  controller.inPackets.toString(),
                                  Icons.arrow_downward,
                                  color: Colors.green,
                                ),
                                _buildStatItem(
                                  'OUT',
                                  controller.outPackets.toString(),
                                  Icons.arrow_upward,
                                  color: Colors.blue,
                                ),
                                _buildStatItem(
                                  'Bytes',
                                  _formatBytes(controller.totalBytes),
                                  Icons.memory,
                                ),
                              ],
                            )
                          else
                            // Mobile: Column layout
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatItem(
                                      'Total',
                                      controller.totalPackets.toString(),
                                      Icons.data_usage,
                                    ),
                                    _buildStatItem(
                                      'IN',
                                      controller.inPackets.toString(),
                                      Icons.arrow_downward,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatItem(
                                      'OUT',
                                      controller.outPackets.toString(),
                                      Icons.arrow_upward,
                                      color: Colors.blue,
                                    ),
                                    _buildStatItem(
                                      'Bytes',
                                      _formatBytes(controller.totalBytes),
                                      Icons.memory,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Legend - Responsive
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16.0,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'IN (Entrada)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'OUT (Salida)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Filters - Collapsible
                  ExpansionTile(
                    title: const Text(
                      'Filters',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: false, // Hidden by default
                    children: [
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quick Filters Row - Responsive
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Protocol:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8.0,
                                            children:
                                                [
                                                      'All',
                                                      'TCP',
                                                      'UDP',
                                                      'ICMP',
                                                      'Unknown',
                                                    ]
                                                    .map(
                                                      (protocol) => FilterChip(
                                                        label: Text(protocol),
                                                        selected:
                                                            controller
                                                                .filterProtocol ==
                                                            protocol,
                                                        onSelected: (selected) {
                                                          if (selected) {
                                                            controller
                                                                .setFilterProtocol(
                                                                  protocol,
                                                                );
                                                          }
                                                        },
                                                        backgroundColor:
                                                            controller
                                                                    .filterProtocol ==
                                                                protocol
                                                            ? Colors.deepPurple
                                                                  .withAlpha(51)
                                                            : null,
                                                        checkmarkColor:
                                                            Colors.deepPurple,
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Direction:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8.0,
                                            children: ['All', 'IN', 'OUT', 'UNK']
                                                .map(
                                                  (direction) => FilterChip(
                                                    label: Row(
                                                      children: [
                                                        Icon(
                                                          direction == 'IN'
                                                              ? Icons
                                                                    .arrow_downward
                                                              : direction ==
                                                                    'OUT'
                                                              ? Icons
                                                                    .arrow_upward
                                                              : Icons
                                                                    .help_outline,
                                                          size: 16,
                                                          color:
                                                              direction == 'IN'
                                                              ? Colors.green
                                                              : direction ==
                                                                    'OUT'
                                                              ? Colors.blue
                                                              : Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(direction),
                                                      ],
                                                    ),
                                                    selected:
                                                        controller
                                                            .filterDirection ==
                                                        direction,
                                                    onSelected: (selected) {
                                                      if (selected) {
                                                        controller
                                                            .setFilterDirection(
                                                              direction,
                                                            );
                                                      }
                                                    },
                                                    backgroundColor:
                                                        controller
                                                                .filterDirection ==
                                                            direction
                                                        ? Colors.deepPurple
                                                              .withAlpha(51)
                                                        : null,
                                                    checkmarkColor:
                                                        Colors.deepPurple,
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Protocol:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 8.0,
                                            children:
                                                [
                                                      'All',
                                                      'TCP',
                                                      'UDP',
                                                      'ICMP',
                                                      'Unknown',
                                                    ]
                                                    .map(
                                                      (protocol) => FilterChip(
                                                        label: Text(protocol),
                                                        selected:
                                                            controller
                                                                .filterProtocol ==
                                                            protocol,
                                                        onSelected: (selected) {
                                                          if (selected) {
                                                            controller
                                                                .setFilterProtocol(
                                                                  protocol,
                                                                );
                                                          }
                                                        },
                                                        backgroundColor:
                                                            controller
                                                                    .filterProtocol ==
                                                                protocol
                                                            ? Colors.deepPurple
                                                                  .withAlpha(51)
                                                            : null,
                                                        checkmarkColor:
                                                            Colors.deepPurple,
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text(
                                          'Direction:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 8.0,
                                            children: ['All', 'IN', 'OUT', 'UNK']
                                                .map(
                                                  (direction) => FilterChip(
                                                    label: Row(
                                                      children: [
                                                        Icon(
                                                          direction == 'IN'
                                                              ? Icons
                                                                    .arrow_downward
                                                              : direction ==
                                                                    'OUT'
                                                              ? Icons
                                                                    .arrow_upward
                                                              : Icons
                                                                    .help_outline,
                                                          size: 16,
                                                          color:
                                                              direction == 'IN'
                                                              ? Colors.green
                                                              : direction ==
                                                                    'OUT'
                                                              ? Colors.blue
                                                              : Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(direction),
                                                      ],
                                                    ),
                                                    selected:
                                                        controller
                                                            .filterDirection ==
                                                        direction,
                                                    onSelected: (selected) {
                                                      if (selected) {
                                                        controller
                                                            .setFilterDirection(
                                                              direction,
                                                            );
                                                      }
                                                    },
                                                    backgroundColor:
                                                        controller
                                                                .filterDirection ==
                                                            direction
                                                        ? Colors.deepPurple
                                                              .withAlpha(51)
                                                        : null,
                                                    checkmarkColor:
                                                        Colors.deepPurple,
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              // Advanced Filters
                              ExpansionTile(
                                title: const Text(
                                  'Advanced Filters',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                children: [
                                  const SizedBox(height: 10),
                                  if (isWide)
                                    // Desktop: 2 columns for advanced filters
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Source IP',
                                                      border:
                                                          OutlineInputBorder(),
                                                      prefixIcon: Icon(
                                                        Icons.location_on,
                                                      ),
                                                    ),
                                                onChanged:
                                                    controller.setFilterSource,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Destination IP',
                                                      border:
                                                          OutlineInputBorder(),
                                                      prefixIcon: Icon(
                                                        Icons.location_on,
                                                      ),
                                                    ),
                                                onChanged:
                                                    controller.setFilterDest,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                decoration: const InputDecoration(
                                                  labelText: 'Port',
                                                  border: OutlineInputBorder(),
                                                  prefixIcon: Icon(
                                                    Icons
                                                        .settings_input_component,
                                                  ),
                                                ),
                                                onChanged:
                                                    controller.setFilterPort,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Source Host',
                                                      border:
                                                          OutlineInputBorder(),
                                                      prefixIcon: Icon(
                                                        Icons.dns,
                                                      ),
                                                    ),
                                                onChanged: controller
                                                    .setFilterSourceHost,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          decoration: const InputDecoration(
                                            labelText: 'Destination Host',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.dns),
                                          ),
                                          onChanged:
                                              controller.setFilterDestHost,
                                        ),
                                      ],
                                    )
                                  else
                                    // Mobile: Single column
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Source IP',
                                                      border:
                                                          OutlineInputBorder(),
                                                      prefixIcon: Icon(
                                                        Icons.location_on,
                                                      ),
                                                    ),
                                                onChanged:
                                                    controller.setFilterSource,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Destination IP',
                                                      border:
                                                          OutlineInputBorder(),
                                                      prefixIcon: Icon(
                                                        Icons.location_on,
                                                      ),
                                                    ),
                                                onChanged:
                                                    controller.setFilterDest,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                decoration: const InputDecoration(
                                                  labelText: 'Port',
                                                  border: OutlineInputBorder(),
                                                  prefixIcon: Icon(
                                                    Icons
                                                        .settings_input_component,
                                                  ),
                                                ),
                                                onChanged:
                                                    controller.setFilterPort,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Source Host',
                                                      border:
                                                          OutlineInputBorder(),
                                                      prefixIcon: Icon(
                                                        Icons.dns,
                                                      ),
                                                    ),
                                                onChanged: controller
                                                    .setFilterSourceHost,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          decoration: const InputDecoration(
                                            labelText: 'Destination Host',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.dns),
                                          ),
                                          onChanged:
                                              controller.setFilterDestHost,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Packet List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.filteredPackets.length,
                    itemBuilder: (context, index) {
                      final packet = controller.filteredPackets[index];
                      return PacketCard(packet: packet);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

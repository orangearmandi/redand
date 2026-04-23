import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/vpn_controller.dart';
import '../widgets/packet_card.dart';

class SimpleHomeView extends StatelessWidget {
  const SimpleHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<VpnController>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('VPN Packet Monitor - Simple View'),
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
              title: const Text('Simple View'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Full View with Filters'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/home');
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
                  // All Packets List - No Filters
                  Text(
                    'All Packets (${controller.packets.length})',
                    style: TextStyle(
                      fontSize: isWide ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.packets.length,
                    itemBuilder: (context, index) {
                      final packet = controller.packets[index];
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

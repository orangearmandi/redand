import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/vpn_controller.dart';
import 'views/home_view.dart';
import 'views/simple_home_view.dart';
import 'views/settings_view.dart';
import 'views/network_info/network_info_view.dart';
import 'views/ping/ping_view.dart';
import 'views/multicast_dns/multicast_dns_view.dart';
import 'views/upnp/upnp_view.dart';
import 'views/socket_connect/socket_connect_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VpnController(),
      child: MaterialApp(
        title: 'VPN Packet Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/simple', // Start with simple view
        routes: {
          '/home': (context) => const HomeView(),
          '/simple': (context) => const SimpleHomeView(),
          '/settings': (context) => const SettingsView(),
          '/network_info': (context) => const NetworkInfoView(),
          '/ping': (context) => const PingView(),
          '/multicast_dns': (context) => const MulticastDnsView(),
          '/upnp': (context) => const UpnpView(),
          '/socket_connect': (context) => const SocketConnectView(),
        },
      ),
    );
  }
}

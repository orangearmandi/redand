import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/vpn_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bufferSizeController;
  late TextEditingController _vpnAddressController;
  late TextEditingController _vpnPrefixLengthController;
  late TextEditingController _dnsServerController;
  late TextEditingController _routeAddressController;
  late TextEditingController _routePrefixLengthController;
  late TextEditingController _sessionNameController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<VpnController>();
    _bufferSizeController = TextEditingController(
      text: controller.bufferSize.toString(),
    );
    _vpnAddressController = TextEditingController(text: controller.vpnAddress);
    _vpnPrefixLengthController = TextEditingController(
      text: controller.vpnPrefixLength.toString(),
    );
    _dnsServerController = TextEditingController(text: controller.dnsServer);
    _routeAddressController = TextEditingController(
      text: controller.routeAddress,
    );
    _routePrefixLengthController = TextEditingController(
      text: controller.routePrefixLength.toString(),
    );
    _sessionNameController = TextEditingController(
      text: controller.sessionName,
    );
  }

  @override
  void dispose() {
    _bufferSizeController.dispose();
    _vpnAddressController.dispose();
    _vpnPrefixLengthController.dispose();
    _dnsServerController.dispose();
    _routeAddressController.dispose();
    _routePrefixLengthController.dispose();
    _sessionNameController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<VpnController>();
      controller.setBufferSize(int.parse(_bufferSizeController.text));
      controller.setVpnAddress(_vpnAddressController.text);
      controller.setVpnPrefixLength(int.parse(_vpnPrefixLengthController.text));
      controller.setDnsServer(_dnsServerController.text);
      controller.setRouteAddress(_routeAddressController.text);
      controller.setRoutePrefixLength(
        int.parse(_routePrefixLengthController.text),
      );
      controller.setSessionName(_sessionNameController.text);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración VPN'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuración del Buffer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bufferSizeController,
                decoration: const InputDecoration(
                  labelText: 'Tamaño del Buffer (bytes)',
                  hintText: 'Ej: 32767',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el tamaño del buffer';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue <= 0) {
                    return 'Debe ser un número entero positivo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Configuración de Red VPN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vpnAddressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección IP VPN',
                  hintText: 'Ej: 10.0.0.2',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la dirección IP VPN';
                  }
                  // Basic IP validation
                  final ipRegex = RegExp(
                    r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$',
                  );
                  if (!ipRegex.hasMatch(value)) {
                    return 'Formato de IP inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vpnPrefixLengthController,
                decoration: const InputDecoration(
                  labelText: 'Longitud del Prefijo VPN',
                  hintText: 'Ej: 24',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la longitud del prefijo';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue < 0 || intValue > 32) {
                    return 'Debe ser un número entre 0 y 32';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dnsServerController,
                decoration: const InputDecoration(
                  labelText: 'Servidor DNS',
                  hintText: 'Ej: 8.8.8.8',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el servidor DNS';
                  }
                  final ipRegex = RegExp(
                    r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$',
                  );
                  if (!ipRegex.hasMatch(value)) {
                    return 'Formato de IP inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Configuración de Ruta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _routeAddressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección de Ruta',
                  hintText: 'Ej: 0.0.0.0',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la dirección de ruta';
                  }
                  final ipRegex = RegExp(
                    r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$',
                  );
                  if (!ipRegex.hasMatch(value)) {
                    return 'Formato de IP inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _routePrefixLengthController,
                decoration: const InputDecoration(
                  labelText: 'Longitud del Prefijo de Ruta',
                  hintText: 'Ej: 0',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la longitud del prefijo de ruta';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue < 0 || intValue > 32) {
                    return 'Debe ser un número entre 0 y 32';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Configuración General',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sessionNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Sesión',
                  hintText: 'Ej: RedAnd VPN',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre de sesión';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Guardar Configuración'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

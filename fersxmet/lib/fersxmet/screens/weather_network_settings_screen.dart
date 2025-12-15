import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/esp32_weather_service.dart';
import 'package:url_launcher/url_launcher.dart';

class WeatherNetworkSettingsScreen extends StatefulWidget {
  const WeatherNetworkSettingsScreen({super.key});

  @override
  State<WeatherNetworkSettingsScreen> createState() =>
      _WeatherNetworkSettingsScreenState();
}

class _WeatherNetworkSettingsScreenState
    extends State<WeatherNetworkSettingsScreen> {
  final ESP32WeatherService _esp32Service = ESP32WeatherService();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '8080');
  
  String _connectionStatus = 'Desconectado';
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('esp32_ip');
    final port = prefs.getInt('esp32_port') ?? 8080;

    if (ip != null) {
      setState(() {
        _ipController.text = ip;
        _portController.text = port.toString();
        _connectionStatus = 'Conectado';
      });
    }
  }

  Future<void> _connectToESP32() async {
    if (_ipController.text.isEmpty) {
      _showSnackBar('Por favor ingresa la IP del ESP32', Colors.red);
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Conectando...';
    });

    try {
      final port = int.tryParse(_portController.text) ?? 8080;
      await _esp32Service.connect(_ipController.text, port);

      setState(() {
        _connectionStatus = 'Conectado';
        _isConnecting = false;
      });

      _showSnackBar('Conectado exitosamente', Colors.green);
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error de conexión';
        _isConnecting = false;
      });

      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _resetWiFi() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar reinicio'),
        content: const Text(
          '¿Reiniciar la configuración WiFi del ESP32?\n\nEl dispositivo se reiniciará y deberás configurarlo nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _esp32Service.forgetWiFi();
        setState(() {
          _ipController.clear();
          _portController.text = '8080';
          _connectionStatus = 'Desconectado';
        });
        _showSnackBar('WiFi reiniciado. Configura el ESP32 nuevamente.', Colors.orange);
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  Future<void> _openConfigPortal() async {
    final url = Uri.parse('http://192.168.4.1');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('No se pudo abrir el portal de configuración', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      _buildConnectionForm(),
                      const SizedBox(height: 20),
                      _buildInstructionsCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración WiFi',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              Text(
                'ESP32',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;

    switch (_connectionStatus) {
      case 'Conectado':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Conectando...':
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  _connectionStatus,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conexión',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'Dirección IP',
              hintText: '192.168.1.100',
              prefixIcon: const Icon(Icons.router),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _portController,
            decoration: InputDecoration(
              labelText: 'Puerto',
              hintText: '8080',
              prefixIcon: const Icon(Icons.settings_ethernet),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isConnecting ? null : _connectToESP32,
              child: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link),
                        SizedBox(width: 10),
                        Text('Conectar'),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _resetWiFi,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Reiniciar WiFi', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Instrucciones',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildStep('1', 'Conecta tu dispositivo a la red WiFi "FERSXMET"'),
          _buildStep('2', 'Abre el portal de configuración'),
          _buildStep('3', 'Selecciona tu red WiFi e ingresa la contraseña'),
          _buildStep('4', 'Anota la dirección IP asignada al ESP32'),
          _buildStep('5', 'Ingresa la IP en esta pantalla y conecta'),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _openConfigPortal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_browser),
                  SizedBox(width: 10),
                  Text('Abrir Portal de Configuración'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

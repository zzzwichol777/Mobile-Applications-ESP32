import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/esp32_provider.dart';

class ESP32ConfigScreen extends StatefulWidget {
  const ESP32ConfigScreen({super.key});

  @override
  State<ESP32ConfigScreen> createState() => _ESP32ConfigScreenState();
}

class _ESP32ConfigScreenState extends State<ESP32ConfigScreen> {
  final _ipController = TextEditingController();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    final esp32 = Provider.of<ESP32Provider>(context, listen: false);
    _ipController.text = esp32.ipAddress;
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() => _isConnecting = true);
    final esp32 = Provider.of<ESP32Provider>(context, listen: false);
    await esp32.saveIP(_ipController.text);
    final success = await esp32.testConnection();
    setState(() => _isConnecting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✓ Conexión exitosa' : '✗ Error de conexión'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración ESP32'),
      ),
      body: Consumer<ESP32Provider>(
        builder: (context, esp32, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            esp32.isConnected ? Icons.check_circle : Icons.error,
                            color: esp32.isConnected ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            esp32.isConnected ? 'Conectado' : 'Desconectado',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (esp32.isConnected) ...[
                        const SizedBox(height: 8),
                        Text(
                          'IP: ${esp32.ipAddress}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Dirección IP del ESP32',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  hintText: '192.168.1.100 o drhome.local',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.router),
                  helperText: 'Puedes usar IP o nombre mDNS',
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isConnecting ? null : _testConnection,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find),
                label: Text(_isConnecting ? 'Conectando...' : 'Probar Conexión'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Instrucciones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _InstructionStep(
                number: 1,
                text: 'Conecta el ESP32 a la corriente',
              ),
              _InstructionStep(
                number: 2,
                text: 'Busca la red WiFi "DrHome" y conéctate',
              ),
              _InstructionStep(
                number: 3,
                text: 'Configura tu red WiFi en el portal',
              ),
              _InstructionStep(
                number: 4,
                text: 'Anota la IP que aparece en el portal',
              ),
              _InstructionStep(
                number: 5,
                text: 'Ingresa la IP aquí y prueba la conexión',
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Consejo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'También puedes usar drhome.local en lugar de la IP si tu red lo soporta.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Olvidar WiFi'),
                      content: const Text(
                        'El ESP32 olvidará la red WiFi configurada y deberás configurarla nuevamente.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Olvidar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await esp32.forgetWiFi();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('WiFi olvidado. Reinicia el ESP32.')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.wifi_off),
                label: const Text('Olvidar WiFi del ESP32'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}

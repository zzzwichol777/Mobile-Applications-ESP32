import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/esp32_service.dart';

class NetworkSettingsScreen extends StatefulWidget {
  const NetworkSettingsScreen({super.key});

  @override
  State<NetworkSettingsScreen> createState() => _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends State<NetworkSettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController =
      TextEditingController(text: '8080');

  bool _isScanning = false;
  final bool _isTesting = false;
  String _connectionStatus = '';

  final ESP32Service _esp32Service = ESP32Service();

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    _ipController.text = prefs.getString('esp32_ip') ?? '';
    _portController.text = (prefs.getInt('esp32_port') ?? 8080).toString();
  }

  Future<void> _testConnection() async {
    try {
      await _esp32Service.connect(
          _ipController.text, int.tryParse(_portController.text) ?? 8080);
      setState(() {
        _connectionStatus = '✅ Conexión exitosa';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Error: $e';
      });
    }
  }

  Future<void> _scanForESP32() async {
    setState(() {
      _isScanning = true;
      _connectionStatus = '🔍 Verificando permisos...';
    });

    // Solicitar permisos
    final locationStatus = await Permission.location.request();
    final nearbyDevicesStatus = await Permission.nearbyWifiDevices.request();

    if (locationStatus.isDenied || nearbyDevicesStatus.isDenied) {
      setState(() {
        _isScanning = false;
        _connectionStatus = '❌ Se requieren permisos para escanear la red';
      });
      return;
    }

    try {
      setState(() {
        _connectionStatus = '🔍 Buscando dispositivo en la red...';
      });

      final foundIP = await _esp32Service.scanForESP32();

      if (foundIP != null) {
        setState(() {
          _ipController.text = foundIP;
          _connectionStatus = '✅ Dispositivo encontrado automáticamente';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dispositivo encontrado en: $foundIP')),
        );
      } else {
        setState(() {
          _connectionStatus =
              '❌ No se encontró el dispositivo. Asegúrate de que esté encendido y conectado a la misma red.';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Error durante la búsqueda: $e';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _saveIpAndPort(String ip, String portStr) async {
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una IP válida')),
      );
      return;
    }

    setState(() {
      _connectionStatus = '🔒 Guardando y verificando...';
    });

    final port = int.tryParse(portStr) ?? 8080;

    try {
      await _esp32Service.connect(ip, port);

      // Si llegamos aquí, la conexión fue exitosa
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('esp32_ip', ip);
      await prefs.setInt('esp32_port', port);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Conexión verificada y configuración guardada')),
      );
      setState(() {
        _connectionStatus = '✅ Dirección guardada correctamente';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ No se pudo conectar a $ip:$port')),
      );
      setState(() {
        _connectionStatus =
            '❌ Falló la verificación. Verifica la IP y conexión.';
      });
    }
  }

  Future<void> _resetWiFi() async {
    try {
      // Primero intentar conectar si no hay conexión
      if (_ipController.text.isNotEmpty) {
        final port = int.tryParse(_portController.text) ?? 8080;
        try {
          await _esp32Service.connect(_ipController.text, port);
        } catch (connectError) {
          // Si no se puede conectar con la IP actual, mostrar error específico
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '❌ No se pudo conectar al ESP32 en ${_ipController.text}:$port. Verifica que esté encendido y conectado.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Por favor ingresa la IP del ESP32 primero'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Mostrar mensaje de progreso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📡 Enviando comando de reinicio WiFi...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Enviar comando de reinicio
      await _esp32Service.forgetWiFi();

      // Limpiar los campos de IP ya que el ESP32 se reiniciará
      setState(() {
        _ipController.clear();
        _portController.text = '8080';
        _connectionStatus =
            '🔄 ESP32 reiniciando WiFi. Busca la red "GASOX" para reconfigurar.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Comando enviado exitosamente. El ESP32 creará la red "GASOX" en unos segundos.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al reiniciar WiFi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Red'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(
              top: 40.0, left: 16.0, right: 16.0, bottom: 60.0),
          children: [
            // Pasos a seguir
            Card(
              color: Colors.black.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pasos a seguir',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStepItem(
                      step: '1',
                      description:
                          'Conectarse a la red creada temporalmente por el ESP32 llamada Gasox',
                    ),
                    _buildStepItem(
                      step: '2',
                      description:
                          'Ir al Portal de configuración que se abrirá en el navegador web predeterminado de su dispositivo al darle clic al botón de abajo.',
                    ),
                    _buildStepItem(
                      step: '3',
                      description:
                          'Conectar el ESP32 al WiFi que el usuario desee ingresando la contraseña y dando clic a conectar.',
                    ),
                    _buildStepItem(
                      step: '4',
                      description:
                          'Una vez conectado a la red, ingresar la ip en la parte de configuración (ya sea "gasox.local" o la automática si se logra detectar) dando clic al botón azul para buscar la dirección.',
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () async {
                          final url = Uri.parse('http://192.168.4.1');
                          if (!await launchUrl(url,
                              mode: LaunchMode.externalApplication)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('No se pudo abrir el navegador.')),
                            );
                          }
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade700,
                                Colors.orange.shade300
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.open_in_browser),
                                const SizedBox(width: 8),
                                const Text(
                                  'Portal de configuración',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Configuración de IP
            Card(
              color: Colors.black.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título con imagen
                    Center(
                      child: Image.asset(
                        'assets/images/tittle_config_ip.png',
                        height: 40,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón para buscar automáticamente
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.zero,
                          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                        ),
                        onPressed: _isScanning ? null : _scanForESP32,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isScanning
                                  ? [Colors.black, Colors.grey.shade900]
                                  : [
                                      Colors.orange.shade700,
                                      Colors.orange.shade300
                                    ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search),
                                const SizedBox(width: 8),
                                const Text(
                                  'Buscar ESP32',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),

                    // Campos de IP y puerto
                    Row(
                      children: [
                        const Text(
                          'IP Del ESP32',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: TextField(
                              controller: _ipController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Ej: 192.168.100.65',
                                hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5)),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Text(
                          'Puerto',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: TextField(
                              controller: _portController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Ej: 8080',
                                hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5)),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _testConnection(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade700,
                                  Colors.orange.shade300
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.network_check),
                                  const SizedBox(width: 8),
                                  const Text('Probar',
                                      style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _saveIpAndPort(
                              _ipController.text, _portController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade700,
                                  Colors.green.shade300
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.save),
                                  const SizedBox(width: 8),
                                  const Text('Guardar',
                                      style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_connectionStatus.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _connectionStatus,
                          style: TextStyle(
                            color: _connectionStatus.contains('✅')
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Manrope',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón para reiniciar WiFi
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmación'),
                      content: const Text(
                          '¿Estás seguro de reiniciar el WiFi del ESP32?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetWiFi();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Acción confirmada')),
                            );
                          },
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade700, Colors.red.shade300],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off),
                        const SizedBox(width: 8),
                        const Text(
                          'Reiniciar WiFi',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({required String step, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                height: 1.4,
                fontFamily: 'Manrope',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

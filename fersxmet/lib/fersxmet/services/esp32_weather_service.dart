import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ESP32WeatherService {
  String? _host;
  int? _port;
  static const Duration timeout = Duration(seconds: 10);

  Future<void> connect(String host, int port) async {
    try {
      String targetHost = host;
      
      // Intentar conexión
      final socket = await Socket.connect(targetHost, port, timeout: const Duration(seconds: 5));
      
      // Verificar que el servidor responda
      socket.write('GET_STATUS\n');
      await socket.flush();
      
      final response = await socket.timeout(const Duration(seconds: 3)).first;
      if (response.isEmpty) {
        throw Exception('El servidor no respondió');
      }
      
      await socket.close();
      
      _host = targetHost;
      _port = port;
      
      // Guardar configuración
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('esp32_ip', targetHost);
      await prefs.setInt('esp32_port', port);
      await prefs.setString('last_known_esp32_ip', targetHost);
      
      print('Conectado a ESP32 en $targetHost:$port');
    } catch (e) {
      print('Error conectando a ESP32: $e');
      throw Exception('No se pudo conectar al ESP32');
    }
  }

  Future<String> sendCommand(String command) async {
    if (_host == null || _port == null) {
      throw Exception('No conectado al ESP32');
    }

    Socket? socket;
    StreamSubscription? sub;
    
    try {
      print('Conectando a $_host:$_port para enviar comando: $command');
      socket = await Socket.connect(_host!, _port!, timeout: const Duration(seconds: 5));
      
      final completer = Completer<String>();
      final buffer = <int>[];
      
      sub = socket.listen(
        (data) {
          buffer.addAll(data);
          final response = utf8.decode(buffer).trim();
          print('Datos recibidos: $response');
          if (!completer.isCompleted) {
            completer.complete(response);
          }
        },
        onError: (error) {
          print('Error en socket: $error');
          if (!completer.isCompleted) {
            completer.completeError('Error de socket: $error');
          }
        },
        onDone: () {
          print('Conexión cerrada');
          if (!completer.isCompleted) {
            if (buffer.isEmpty) {
              completer.completeError('Conexión cerrada sin respuesta');
            } else {
              completer.complete(utf8.decode(buffer).trim());
            }
          }
        },
        cancelOnError: true,
      );
      
      print('Enviando comando: $command');
      socket.write('$command\n');
      await socket.flush();
      
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          print('Timeout esperando respuesta para: $command');
          throw TimeoutException('No se recibió respuesta en ${timeout.inSeconds} segundos');
        },
      );
    } catch (e) {
      print('Error en sendCommand: $e');
      rethrow;
    } finally {
      try {
        await sub?.cancel();
        await socket?.close();
      } catch (closeError) {
        print('Error al cerrar socket: $closeError');
      }
    }
  }

  Future<Map<String, double>> getWeatherData() async {
    try {
      final response = await sendCommand('GET_WEATHER');
      print('Respuesta del ESP32: $response');
      
      Map<String, dynamic> values = jsonDecode(response);
      return {
        'temperature': (values['temperature'] as num).toDouble(),
        'humidity': (values['humidity'] as num).toDouble(),
        'luminosity': (values['luminosity'] as num).toDouble(),
      };
    } catch (e) {
      print('Error obteniendo datos meteorológicos: $e');
      throw Exception('Error al obtener datos del sensor');
    }
  }

  Future<Map<String, double>> getThermalData() async {
    try {
      final response = await sendCommand('GET_THERMAL');
      print('Respuesta térmica del ESP32: $response');
      
      Map<String, dynamic> values = jsonDecode(response);
      return {
        'ambient_temp': (values['ambient_temp'] as num).toDouble(),
        'object_temp': (values['object_temp'] as num).toDouble(),
        'difference': (values['difference'] as num).toDouble(),
      };
    } catch (e) {
      print('Error obteniendo datos térmicos: $e');
      throw Exception('Error al obtener datos térmicos');
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await sendCommand('GET_STATUS');
      print('Estado del ESP32: $response');
      
      return jsonDecode(response);
    } catch (e) {
      print('Error obteniendo estado: $e');
      throw Exception('Error al obtener estado del sistema');
    }
  }

  Future<void> forgetWiFi() async {
    if (_host == null || _port == null) {
      throw Exception('No hay conexión establecida con el ESP32');
    }

    Socket? socket;
    try {
      print('Enviando comando FORGET_WIFI a $_host:$_port');
      
      socket = await Socket.connect(_host!, _port!, timeout: const Duration(seconds: 5));
      
      socket.write('FORGET_WIFI\n');
      await socket.flush();
      
      try {
        final response = await socket.timeout(const Duration(seconds: 3)).first;
        final responseStr = String.fromCharCodes(response).trim();
        print('Respuesta del ESP32: $responseStr');
      } catch (timeoutError) {
        print('ESP32 no respondió (probablemente se reinició)');
      }
      
      _host = null;
      _port = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('esp32_ip');
      await prefs.remove('esp32_port');
      await prefs.remove('last_known_esp32_ip');
      
      print('Comando FORGET_WIFI enviado exitosamente');
    } catch (e) {
      print('Error enviando FORGET_WIFI: $e');
      throw Exception('Error al enviar comando de reinicio WiFi: $e');
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  bool get isConnected => _host != null && _port != null;
}

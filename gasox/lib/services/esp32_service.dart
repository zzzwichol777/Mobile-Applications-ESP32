import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multicast_dns/multicast_dns.dart';

class ESP32Service {
  String? _host;
  int? _port;
  static const Duration timeout = Duration(seconds: 5);
  static const int defaultPort = 8080;

  Future<InternetAddress?> _resolveMdns(String hostname) async {
    final MDnsClient client = MDnsClient();
    try {
      await client.start();
      print('Buscando $hostname.local...');

      // Timeout para la búsqueda mDNS
      final searchTimeout = Timer(const Duration(seconds: 8), () {
        client.stop();
      });

      // Buscar directamente el nombre del host
      await for (final IPAddressResourceRecord record
          in client.lookup<IPAddressResourceRecord>(
        ResourceRecordQuery.addressIPv4('$hostname.local'),
      )) {
        print('Encontrado: ${record.address}');
        searchTimeout.cancel();
        client.stop();
        return record.address;
      }

      // Si no se encuentra, intentar con servicios HTTP
      await for (final PtrResourceRecord ptr
          in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_http._tcp.local'),
      )) {
        if (ptr.domainName.toLowerCase().contains(hostname.toLowerCase())) {
          await for (final SrvResourceRecord srv
              in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName),
          )) {
            await for (final IPAddressResourceRecord ip
                in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target),
            )) {
              print('Encontrado via HTTP: ${ip.address}');
              searchTimeout.cancel();
              client.stop();
              return ip.address;
            }
          }
        }
      }

      searchTimeout.cancel();
      client.stop();
      print('No se encontró $hostname.local después de 8 segundos');
      return null;
    } catch (e) {
      print('Error mDNS: $e');
      try {
        client.stop();
      } catch (_) {}
      return null;
    }
  }

  Future<void> connect(String host, int port) async {
    try {
      String targetHost = host;

      // Si es gasox.local, intentar resolver primero
      if (host.toLowerCase().contains('gasox.local') ||
          host.toLowerCase() == 'gasox.local') {
        print('Intentando resolver gasox.local...');
        final resolved = await _resolveMdns('gasox');
        if (resolved != null) {
          targetHost = resolved.address;
          print('gasox.local resuelto a: $targetHost');
        } else {
          print(
              'No se pudo resolver gasox.local, intentando conexión directa...');
          // Intentar con la IP conocida como fallback
          final prefs = await SharedPreferences.getInstance();
          final lastKnownIP = prefs.getString('last_known_esp32_ip');
          if (lastKnownIP != null && lastKnownIP.isNotEmpty) {
            print('Intentando con última IP conocida: $lastKnownIP');
            targetHost = lastKnownIP;
          } else {
            throw Exception(
                'No se pudo resolver gasox.local y no hay IP de respaldo');
          }
        }
      }

      _host = targetHost;
      _port = port;

      // Intenta conectar con timeout
      final socket = await Socket.connect(_host!, _port!,
              timeout: const Duration(seconds: 5))
          .catchError((e) {
        throw Exception(
            'No se pudo conectar a $_host:$_port - ${e.toString()}');
      });

      // Verifica que el servidor responda
      socket.write('GET_VALUES\n');
      await socket.flush();

      // Espera respuesta
      final response = await socket.timeout(const Duration(seconds: 3)).first;

      if (response.isEmpty) {
        throw Exception('El servidor no respondió');
      }

      socket.destroy();

      // Guardar la IP que funcionó
      await setESP32IP(_host!, port);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_known_esp32_ip', _host!);

      print('Conexión exitosa a $_host:$_port');
    } catch (e) {
      _host = null;
      _port = null;
      print('Error de conexión: $e');
      rethrow;
    }
  }

  Future<bool> ping() async {
    try {
      final response = await sendCommand('PING');
      return response.contains('PONG');
    } catch (e) {
      return false;
    }
  }

  Future<String> sendCommand(String command) async {
    if (_host == null || _port == null) {
      throw Exception('No hay conexión establecida');
    }

    Socket? socket;
    StreamSubscription? sub;

    try {
      print('Conectando a $_host:$_port para enviar comando: $command');
      socket = await Socket.connect(_host!, _port!,
          timeout: const Duration(seconds: 5));

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

      // Aumentamos el tiempo de espera para dar más margen
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Timeout esperando respuesta para: $command');
          throw TimeoutException(
              'No se recibió respuesta en 10 segundos para el comando: $command');
        },
      );
    } catch (e) {
      print('Error en sendCommand: $e');
      rethrow;
    } finally {
      // Asegurarse de limpiar los recursos
      try {
        await sub?.cancel();
        await socket?.close();
      } catch (closeError) {
        print('Error al cerrar socket: $closeError');
      }
    }
  }

  Future<bool> testConnection(String ip, int port) async {
    try {
      final socket =
          await Socket.connect(ip, port, timeout: const Duration(seconds: 2));

      socket.write('GET_VALUES\n');
      await socket.flush();

      final response = await socket.timeout(const Duration(seconds: 2)).first;

      socket.destroy();
      return response.isNotEmpty;
    } catch (e) {
      print('Test de conexión fallido para $ip:$port - $e');
      return false;
    }
  }

  Future<void> setESP32IP(String ip, [int port = defaultPort]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_ip', ip);
    await prefs.setInt('esp32_port', port);
  }

  Future<String?> scanForESP32() async {
    final resolved = await _resolveMdns('gasox');
    if (resolved != null) return resolved.address;

    try {
      final interfaces = await NetworkInterface.list();
      String? networkBase;
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              networkBase = '${parts[0]}.${parts[1]}.${parts[2]}';
              break;
            }
          }
        }
        if (networkBase != null) break;
      }
      if (networkBase == null) {
        throw Exception('No se encontró una interfaz de red válida');
      }
      for (int i = 100; i <= 110; i++) {
        final testIP = '$networkBase.$i';
        if (await testConnection(testIP, defaultPort)) {
          return testIP;
        }
      }
    } catch (e) {
      throw Exception('Error al escanear la red: $e');
    }
    return null;
  }

  Future<void> forgetWiFi() async {
    if (_host == null || _port == null) {
      throw Exception('No hay conexión establecida con el ESP32');
    }

    Socket? socket;
    try {
      print('Enviando comando FORGET_WIFI a $_host:$_port');

      // Conectar al ESP32
      socket = await Socket.connect(_host!, _port!,
          timeout: const Duration(seconds: 5));

      // Enviar comando
      socket.write('FORGET_WIFI\n');
      await socket.flush();

      // Esperar confirmación (el ESP32 debería responder antes de reiniciarse)
      try {
        final response = await socket.timeout(const Duration(seconds: 3)).first;
        final responseStr = String.fromCharCodes(response).trim();
        print('Respuesta del ESP32: $responseStr');

        if (responseStr.contains('OLVIDANDO_WIFI')) {
          print('ESP32 confirmó que olvidará la WiFi');
        }
      } catch (timeoutError) {
        print('ESP32 no respondió (probablemente se reinició)');
      }

      // Limpiar la conexión local ya que el ESP32 se reiniciará
      _host = null;
      _port = null;

      // Limpiar las preferencias guardadas
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

  Future<Map<String, int>> getSensorValues() async {
    try {
      final response = await sendCommand('GET_VALUES');
      print('Respuesta del ESP32: $response');

      // Parsear respuesta JSON
      Map<String, dynamic> values = jsonDecode(response);
      return {
        'mq4': values['mq4'] as int,
        'mq7': values['mq7'] as int,
      };
    } catch (e) {
      print('Error al obtener los valores de los sensores: $e');
      throw Exception('Falló la obtención de valores de sensores');
    }
  }

  Future<bool> getAlarmState() async {
    final response = await sendCommand('GET_ALARM_STATE');
    return response.trim() == 'ALARMA_ACTIVA';
  }

  Future<void> setMQ4Threshold(int threshold) async {
    if (threshold < 0 || threshold > 80000) {
      throw Exception('El umbral debe estar entre 0 y 80000');
    }

    try {
      print('Enviando comando SET_THRESHOLD_MQ4:$threshold al ESP32');
      final response = await sendCommand('SET_THRESHOLD_MQ4:$threshold');
      print('Respuesta MQ4: $response');

      // Intentar parsear la respuesta JSON
      try {
        final data = jsonDecode(response);
        if (data['status'] != 'ok') {
          throw Exception(
              'Error actualizando umbral MQ4: ${data['message'] ?? "Respuesta inválida"}');
        }
        print('Umbral MQ4 actualizado correctamente a $threshold');
      } catch (parseError) {
        print('Error parseando respuesta: $parseError');
        if (response.contains('error')) {
          throw Exception('Error actualizando umbral MQ4: $response');
        } else if (!response.contains('ok')) {
          throw Exception('Respuesta inesperada del ESP32: $response');
        }
      }
    } catch (e) {
      print('Error setting MQ4 threshold: $e');
      rethrow;
    }
  }

  Future<void> setMQ7Threshold(int threshold) async {
    if (threshold < 0 || threshold > 80000) {
      throw Exception('El umbral debe estar entre 0 y 80000');
    }

    try {
      print('Enviando comando SET_THRESHOLD_MQ7:$threshold al ESP32');
      final response = await sendCommand('SET_THRESHOLD_MQ7:$threshold');
      print('Respuesta MQ7: $response');

      // Intentar parsear la respuesta JSON
      try {
        final data = jsonDecode(response);
        if (data['status'] != 'ok') {
          throw Exception(
              'Error actualizando umbral MQ7: ${data['message'] ?? "Respuesta inválida"}');
        }
        print('Umbral MQ7 actualizado correctamente a $threshold');
      } catch (parseError) {
        print('Error parseando respuesta: $parseError');
        if (response.contains('error')) {
          throw Exception('Error actualizando umbral MQ7: $response');
        } else if (!response.contains('ok')) {
          throw Exception('Respuesta inesperada del ESP32: $response');
        }
      }
    } catch (e) {
      print('Error setting MQ7 threshold: $e');
      rethrow;
    }
  }

  Future<void> checkAlarmBackground() async {
    await getAlarmState();
  }
}

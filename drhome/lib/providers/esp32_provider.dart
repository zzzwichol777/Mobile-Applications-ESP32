import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ESP32Provider extends ChangeNotifier {
  String _ipAddress = '';
  bool _isConnected = false;
  int _heartRate = 0;
  int _spo2 = 0;
  double _bodyTemp = 0.0;
  bool _fingerDetected = false;
  Timer? _updateTimer;

  String get ipAddress => _ipAddress;
  bool get isConnected => _isConnected;
  int get heartRate => _heartRate;
  int get spo2 => _spo2;
  double get bodyTemp => _bodyTemp;
  bool get fingerDetected => _fingerDetected;

  ESP32Provider() {
    _loadIP();
  }

  Future<void> _loadIP() async {
    final prefs = await SharedPreferences.getInstance();
    _ipAddress = prefs.getString('esp32_ip') ?? '';
    if (_ipAddress.isNotEmpty) {
      await testConnection();
    }
    notifyListeners();
  }

  Future<void> saveIP(String ip) async {
    _ipAddress = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_ip', ip);
    notifyListeners();
  }

  Future<bool> testConnection() async {
    try {
      print('Probando conexión con $_ipAddress...');
      final response = await _sendCommand('GET_STATUS');
      
      if (response != null && response.isNotEmpty) {
        print('✓ Conexión exitosa!');
        _isConnected = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('✗ Error en testConnection: $e');
    }
    
    _isConnected = false;
    notifyListeners();
    return false;
  }

  Future<String?> _sendCommand(String command) async {
    if (_ipAddress.isEmpty) return null;

    Socket? socket;
    try {
      print('Conectando a $_ipAddress:8080...');
      socket = await Socket.connect(
        _ipAddress, 
        8080,
        timeout: const Duration(seconds: 3),
      );
      
      print('Enviando comando: $command');
      socket.write('$command\n');
      await socket.flush();

      // Leer respuesta de forma simple
      final response = await socket.timeout(
        const Duration(seconds: 3),
      ).first;

      final data = utf8.decode(response);
      await socket.close();
      
      print('Respuesta recibida: $data');
      return data.trim();
      
    } catch (e) {
      print('Error enviando comando "$command": $e');
      if (socket != null) {
        try {
          await socket.close();
        } catch (_) {}
      }
      return null;
    }
  }

  Future<void> startMeasurement() async {
    await _sendCommand('START_MEASUREMENT');
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      updateVitals();
    });
  }

  Future<void> stopMeasurement() async {
    await _sendCommand('STOP_MEASUREMENT');
    _updateTimer?.cancel();
  }

  Future<void> updateVitals() async {
    try {
      final response = await _sendCommand('GET_VITALS');
      if (response != null && response.isNotEmpty) {
        try {
          final data = jsonDecode(response);
          _heartRate = (data['heart_rate'] ?? 0).toInt();
          _spo2 = (data['spo2'] ?? 0).toInt();
          _bodyTemp = (data['body_temp'] ?? 0.0).toDouble();
          _fingerDetected = data['finger_detected'] ?? false;
          _isConnected = true;
          print('Vitales actualizados: HR=$_heartRate, SpO2=$_spo2, Temp=$_bodyTemp');
          notifyListeners();
        } catch (e) {
          print('Error parseando JSON: $e');
          print('Respuesta recibida: $response');
        }
      } else {
        print('Respuesta vacía al actualizar vitales');
        _isConnected = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error actualizando vitales: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  Future<void> forgetWiFi() async {
    await _sendCommand('FORGET_WIFI');
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

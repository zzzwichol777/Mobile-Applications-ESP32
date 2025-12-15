import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  double alarmVolume = 0.8;
  String _selectedAlarmSound = 'assets/sounds/alarm1.mp3';
  String? _customAlarmPath;
  AudioPlayer? _testPlayer;

  final List<Map<String, String>> _predefinedSounds = [
    {'name': 'Alarma 1', 'path': 'assets/sounds/alarm1.mp3'},
    {'name': 'Alarma 2', 'path': 'assets/sounds/alarm2.mp3'},
    {'name': 'Alarma 3', 'path': 'assets/sounds/alarm3.mp3'},
  ];

  // Declara la lista como variable de estado
  List<Map<String, dynamic>> _recentNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadRecentNotifications();
  }

  @override
  void dispose() {
    _testPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('show_notifications') ?? true;
      soundEnabled = prefs.getBool('notifications_sound') ?? true;
      vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;
      alarmVolume = prefs.getDouble('alarm_volume') ?? 0.8;
      _selectedAlarmSound =
          prefs.getString('selected_alarm_sound') ?? 'assets/sounds/alarm1.mp3';
      _customAlarmPath = prefs.getString('custom_alarm_path');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_sound', soundEnabled);
    await prefs.setBool('notifications_vibration', vibrationEnabled);
    await prefs.setBool('notifications_enabled', notificationsEnabled);
    await prefs.setDouble('alarm_volume', alarmVolume);
    await prefs.setString('selected_alarm_sound', _selectedAlarmSound);
    if (_customAlarmPath != null) {
      await prefs.setString('custom_alarm_path', _customAlarmPath!);
    }
  }

  Future<void> _testAlarmSound() async {
    try {
      await _stopTestSound();
      _testPlayer = AudioPlayer();
      await _testPlayer!.setVolume(alarmVolume);

      String soundPath = _customAlarmPath ?? _selectedAlarmSound;

      if (soundPath.startsWith('assets/')) {
        await _testPlayer!
            .play(AssetSource(soundPath.replaceFirst('assets/', '')));
      } else {
        await _testPlayer!.play(DeviceFileSource(soundPath));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reproduciendo sonido de prueba'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reproducir sonido: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _stopTestSound() async {
    if (_testPlayer != null) {
      await _testPlayer!.stop();
      await _testPlayer!.dispose();
      _testPlayer = null;
    }
  }

  Future<void> _pickCustomAlarmSound() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _customAlarmPath = result.files.single.path!;
          _selectedAlarmSound = 'custom';
        });

        await _saveSettings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sonido personalizado seleccionado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar archivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadRecentNotifications() async {
    setState(() {
      _recentNotifications = [
        {
          'title': 'Alerta de Gas',
          'message': 'Nivel de gas detectado: Alto',
          'time': DateTime.now().subtract(const Duration(minutes: 15)),
          'type': 'critical',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          MediaQuery.of(context).orientation == Orientation.portrait,
      appBar: MediaQuery.of(context).orientation == Orientation.landscape
          ? AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              toolbarHeight: 56,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Notificaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.save,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () async {
                    await _saveSettings();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuración guardada'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ],
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: ClipRect(
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/banners/banner_notifications_screen.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    toolbarHeight: 56,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.save,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () async {
                          await _saveSettings();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Configuración guardada'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
              top: 40.0, left: 16.0, right: 16.0, bottom: 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Configuración general
              const SizedBox(height: 64),
              Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Notificaciones',
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'Manrope')),
                        subtitle: const Text('Recibir notificaciones',
                            style: TextStyle(
                                color: Colors.white70, fontFamily: 'Manrope')),
                        value: notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            notificationsEnabled = value;
                          });
                        },
                        secondary: const Icon(Icons.notifications,
                            color: Colors.orange),
                        activeColor: Colors.orange.shade700,
                        activeTrackColor: Colors.orange.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('Sonido',
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'Manrope')),
                        subtitle: const Text('Reproducir sonido de alarma',
                            style: TextStyle(
                                color: Colors.white70, fontFamily: 'Manrope')),
                        value: soundEnabled,
                        onChanged: notificationsEnabled
                            ? (value) {
                                setState(() {
                                  soundEnabled = value;
                                });
                              }
                            : null,
                        secondary:
                            const Icon(Icons.volume_up, color: Colors.orange),
                        activeColor: Colors.orange.shade700,
                        activeTrackColor: Colors.orange.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('Vibración',
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'Manrope')),
                        subtitle: const Text(
                            'Vibrar cuando se active la alarma',
                            style: TextStyle(
                                color: Colors.white70, fontFamily: 'Manrope')),
                        value: vibrationEnabled,
                        onChanged: notificationsEnabled
                            ? (value) {
                                setState(() {
                                  vibrationEnabled = value;
                                });
                              }
                            : null,
                        secondary:
                            const Icon(Icons.vibration, color: Colors.orange),
                        activeColor: Colors.orange.shade700,
                        activeTrackColor: Colors.orange.shade300,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Control de volumen
              Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Volumen de Alarma',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.volume_down, color: Colors.white70),
                          Expanded(
                            child: Slider(
                              value: alarmVolume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: Colors.orange,
                              inactiveColor: Colors.grey.shade800,
                              onChanged: soundEnabled
                                  ? (value) {
                                      setState(() {
                                        alarmVolume = value;
                                      });
                                    }
                                  : null,
                            ),
                          ),
                          const Icon(Icons.volume_up, color: Colors.white70),
                        ],
                      ),
                      Text(
                        'Volumen: ${(alarmVolume * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: soundEnabled ? _testAlarmSound : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.zero,
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: Colors.orange,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: soundEnabled
                                      ? [
                                          Colors.orange.shade700,
                                          Colors.orange.shade300
                                        ]
                                      : [Colors.black, Colors.grey.shade900],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.play_arrow,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    const Text('Probar Sonido',
                                        style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: soundEnabled ? _stopTestSound : null,
                            child: const Text('Cancelar',
                                style: TextStyle(
                                    color: Colors.red, fontFamily: 'Manrope')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Selección de sonido
              Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sonido de Alarma',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._predefinedSounds.map((sound) {
                        final isSelected = _selectedAlarmSound == sound['path'];
                        return RadioListTile<String>(
                          title: Text(
                            sound['name']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          value: sound['path']!,
                          groupValue: _selectedAlarmSound,
                          onChanged: soundEnabled
                              ? (value) {
                                  setState(() {
                                    _selectedAlarmSound = value!;
                                    _customAlarmPath = null;
                                  });
                                }
                              : null,
                          activeColor: Colors.orange,
                          selected: isSelected,
                          secondary: Icon(
                            Icons.music_note,
                            color: isSelected ? Colors.orange : Colors.white70,
                          ),
                        );
                      }).toList(),
                      RadioListTile<String>(
                        title: const Text(
                          'Sonido Personalizado',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        subtitle: _customAlarmPath != null
                            ? Text(
                                _customAlarmPath!.split('/').last,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'Manrope',
                                ),
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        value: 'custom',
                        groupValue: _customAlarmPath != null
                            ? 'custom'
                            : _selectedAlarmSound,
                        onChanged: soundEnabled
                            ? (value) {
                                if (value == 'custom') {
                                  _pickCustomAlarmSound();
                                }
                              }
                            : null,
                        activeColor: Colors.orange,
                        secondary: IconButton(
                          icon: const Icon(Icons.folder_open,
                              color: Colors.white70),
                          onPressed:
                              soundEnabled ? _pickCustomAlarmSound : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed:
                              soundEnabled ? _pickCustomAlarmSound : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.zero,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.orange,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: soundEnabled
                                    ? [
                                        Colors.orange.shade700,
                                        Colors.orange.shade300
                                      ]
                                    : [Colors.black, Colors.grey.shade900],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.upload_file,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text('Seleccionar Archivo',
                                      style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
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

              const SizedBox(height: 16),

              // Información adicional
              Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'Información Importante',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Las notificaciones de alarma son críticas para su seguridad',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontFamily: 'Manrope'),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Mantenga el volumen alto para escuchar las alertas',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontFamily: 'Manrope'),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• La vibración funciona incluso en modo silencioso',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontFamily: 'Manrope'),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Los archivos de audio personalizados deben estar en formato MP3 o WAV',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontFamily: 'Manrope'),
                      ),
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
}

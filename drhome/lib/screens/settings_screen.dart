import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme.dart';
import 'esp32_config_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionHeader(title: 'Apariencia'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Column(
                children: AppThemeMode.values.map((mode) {
                  return RadioListTile<AppThemeMode>(
                    value: mode,
                    groupValue: themeProvider.currentTheme,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setTheme(value);
                      }
                    },
                    title: Text(AppTheme.getThemeName(mode)),
                    secondary: Icon(AppTheme.getThemeIcon(mode)),
                  );
                }).toList(),
              );
            },
          ),
          const Divider(),
          _SectionHeader(title: 'Dispositivo'),
          ListTile(
            leading: const Icon(Icons.router),
            title: const Text('Configurar ESP32'),
            subtitle: const Text('Conectar con el dispositivo médico'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ESP32ConfigScreen()),
              );
            },
          ),
          const Divider(),
          _SectionHeader(title: 'Información'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de DrHome'),
            subtitle: const Text('Versión 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'DrHome',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 32),
                ),
                children: [
                  const Text(
                    'Sistema médico profesional para monitoreo de signos vitales.\n\n'
                    'Desarrollado con Flutter y ESP32.\n\n'
                    '⚕️ Este sistema es de uso orientativo. Siempre consulte con un profesional de la salud.',
                  ),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_information),
            title: const Text('Aviso Médico'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('⚕️ Aviso Médico Importante'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'DrHome es un sistema de monitoreo de signos vitales diseñado con fines educativos y de seguimiento personal.\n\n'
                      'IMPORTANTE:\n\n'
                      '• Los diagnósticos automáticos son orientativos\n'
                      '• No reemplaza la consulta médica profesional\n'
                      '• En caso de emergencia, contacte servicios médicos\n'
                      '• Los sensores deben estar calibrados correctamente\n'
                      '• Consulte con su médico antes de tomar decisiones basadas en estas mediciones\n\n'
                      'Este dispositivo NO está certificado como equipo médico profesional.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ayuda'),
            subtitle: const Text('Guía de uso y soporte'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ayuda'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cómo usar DrHome:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        Text('1. Agrega un paciente en la pestaña Pacientes'),
                        SizedBox(height: 8),
                        Text('2. Configura tu ESP32 en Ajustes'),
                        SizedBox(height: 8),
                        Text('3. Selecciona un paciente'),
                        SizedBox(height: 8),
                        Text('4. Ve a Medición y coloca el dedo en el sensor'),
                        SizedBox(height: 8),
                        Text('5. Inicia la medición y espera 10-15 segundos'),
                        SizedBox(height: 8),
                        Text('6. Guarda la medición con notas opcionales'),
                        SizedBox(height: 8),
                        Text('7. Revisa el historial y diagnósticos en el perfil del paciente'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

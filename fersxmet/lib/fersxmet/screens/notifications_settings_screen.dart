import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_manager.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      soundEnabled = prefs.getBool('notifications_sound') ?? true;
      vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', notificationsEnabled);
    await prefs.setBool('notifications_sound', soundEnabled);
    await prefs.setBool('notifications_vibration', vibrationEnabled);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Configuración guardada'),
            ],
          ),
          backgroundColor: ThemeManager.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Color _getDarkThemeColor(Color primaryColor) {
    final hslColor = HSLColor.fromColor(primaryColor);
    final darkColor = hslColor.withLightness(0.15).withSaturation(0.4);
    return darkColor.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ThemeManager.primaryColor;
    final darkBgColor = _getDarkThemeColor(primaryColor);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              darkBgColor.withOpacity(0.3),
              darkBgColor.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(primaryColor),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 32),
                      _buildSettingsCard(primaryColor),
                      const SizedBox(height: 24),
                      _buildInfoCard(primaryColor),
                      const SizedBox(height: 24),
                      _buildAnomaliesCard(primaryColor),
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

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.3),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text(
            'Notificaciones',
            style: const TextStyle(
              fontFamily: 'ExpletusSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.save, color: primaryColor),
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración de Alertas',
          style: const TextStyle(
            fontFamily: 'ExpletusSans',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Personaliza cómo recibes las notificaciones',
          style: const TextStyle(
            fontFamily: 'ExpletusSans',
            fontSize: 14,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_active,
            title: 'Notificaciones',
            subtitle: 'Recibir alertas de anomalías',
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() => notificationsEnabled = value);
            },
            primaryColor: primaryColor,
          ),
          const Divider(color: Colors.white12, height: 32),
          _buildSwitchTile(
            icon: Icons.volume_up,
            title: 'Sonido',
            subtitle: 'Reproducir sonido en alertas',
            value: soundEnabled,
            onChanged: notificationsEnabled
                ? (value) {
                    setState(() => soundEnabled = value);
                  }
                : null,
            primaryColor: primaryColor,
          ),
          const Divider(color: Colors.white12, height: 32),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: 'Vibración',
            subtitle: 'Vibrar en alertas críticas',
            value: vibrationEnabled,
            onChanged: notificationsEnabled
                ? (value) {
                    setState(() => vibrationEnabled = value);
                  }
                : null,
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
    required Color primaryColor,
  }) {
    final isEnabled = onChanged != null;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isEnabled ? primaryColor : Colors.grey).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isEnabled ? primaryColor : Colors.grey,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? Colors.white : Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 12,
                  color: isEnabled ? Colors.white60 : Colors.white38,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: primaryColor,
          activeTrackColor: primaryColor.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Información',
                style: const TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Las notificaciones son importantes para tu seguridad'),
          _buildInfoItem('Recibirás alertas cuando se detecten anomalías'),
          _buildInfoItem('Las alertas críticas siempre vibrarán'),
          _buildInfoItem('Puedes desactivar las notificaciones en cualquier momento'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ThemeManager.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'ExpletusSans',
                fontSize: 13,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Anomalías Detectadas',
                style: const TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnomalyItem('🔥', 'Temperatura alta', '> 35°C'),
          _buildAnomalyItem('❄️', 'Temperatura baja', '< 10°C'),
          _buildAnomalyItem('💧', 'Humedad alta', '> 80%'),
          _buildAnomalyItem('🏜️', 'Humedad baja', '< 30%'),
          _buildAnomalyItem('☀️', 'Luz solar directa', '> 10,000 lux'),
          _buildAnomalyItem('🔥', 'Objeto caliente', '+15°C diferencia'),
          _buildAnomalyItem('🧊', 'Objeto frío', '-10°C diferencia'),
        ],
      ),
    );
  }

  Widget _buildAnomalyItem(String emoji, String title, String threshold) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'ExpletusSans',
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeManager.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ThemeManager.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              threshold,
              style: TextStyle(
                fontFamily: 'ExpletusSans',
                fontSize: 11,
                color: ThemeManager.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

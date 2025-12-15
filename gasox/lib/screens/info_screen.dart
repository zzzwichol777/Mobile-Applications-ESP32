import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          MediaQuery.of(context).orientation == Orientation.portrait,
      appBar: MediaQuery.of(context).orientation == Orientation.landscape
          ? AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Información',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/banners/banner_info_screen.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
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
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).orientation == Orientation.portrait
                ? 100.0
                : 16.0,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con logo/título
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 50,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sistema de Detección de Gases Peligrosos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontFamily: 'Manrope',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ¿Qué es GASOX?
              _buildSectionCard(
                title: '¿Qué es GASOX?',
                icon: Icons.info_outline,
                color: Colors.orange,
                child: const Text(
                  'GASOX es un sistema inteligente de detección de gases peligrosos que utiliza tecnología ESP32 y sensores especializados para monitorear la calidad del aire en tiempo real. El sistema está diseñado para proteger tu hogar y familia mediante la detección temprana de gases tóxicos y combustibles.',
                  style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.white,
                      fontFamily: 'Manrope'),
                ),
              ),

              const SizedBox(height: 16),

              // Sensores del sistema
              _buildSectionCard(
                title: 'Sensores del Sistema',
                icon: Icons.sensors,
                color: Colors.orange,
                child: Column(
                  children: [
                    _buildSensorInfo(
                      name: 'Sensor MQ4',
                      description: 'Detector de Metano (CH₄)',
                      details:
                          'Detecta gases combustibles como metano, gas natural y GLP. Ideal para cocinas y áreas con instalaciones de gas.',
                      icon: 'assets/images/metano.png',
                      color: Colors.orange,
                      ranges: 'Rango: 200-10,000 ppm',
                    ),
                    const SizedBox(height: 16),
                    _buildSensorInfo(
                      name: 'Sensor MQ7',
                      description: 'Detector de Monóxido de Carbono (CO)',
                      details:
                          'Detecta monóxido de carbono, un gas inodoro e incoloro extremadamente peligroso. Esencial para prevenir intoxicaciones.',
                      icon: 'assets/images/co.png',
                      color: Colors.white70,
                      ranges: 'Rango: 20-2,000 ppm',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Cómo funciona el circuito
              _buildSectionCard(
                title: 'Cómo Funciona el Circuito',
                icon: Icons.memory,
                color: Colors.orange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepItem(
                      step: '1',
                      title: 'Detección',
                      description:
                          'Los sensores MQ4 y MQ7 detectan continuamente la concentración de gases en el ambiente.',
                    ),
                    _buildStepItem(
                      step: '2',
                      title: 'Procesamiento',
                      description:
                          'El ESP32 procesa las señales de los sensores y las convierte en valores PPM (partes por millón).',
                    ),
                    _buildStepItem(
                      step: '3',
                      title: 'Comparación',
                      description:
                          'Los valores se comparan con los umbrales establecidos por el usuario en la aplicación.',
                    ),
                    _buildStepItem(
                      step: '4',
                      title: 'Alerta',
                      description:
                          'Si se superan los límites, se activa la alarma sonora y se envía notificación a la app.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Cómo funciona la app
              _buildSectionCard(
                title: 'Cómo Funciona la App',
                icon: Icons.smartphone,
                color: Colors.orange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem(
                      icon: Icons.wifi,
                      title: 'Configuración WiFi',
                      description:
                          'Conecta tu ESP32 a la red WiFi de tu hogar para comunicación en tiempo real.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.tune,
                      title: 'Ajuste de Umbrales',
                      description:
                          'Personaliza los límites de detección para cada sensor según tus necesidades.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.notifications_active,
                      title: 'Notificaciones',
                      description:
                          'Recibe alertas instantáneas cuando se detecten niveles peligrosos de gas.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.storage,
                      title: 'Base de Datos',
                      description:
                          'Guarda y visualiza el historial completo de mediciones y alarmas.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Niveles de peligro
              _buildSectionCard(
                title: 'Niveles de Peligro',
                icon: Icons.warning,
                color: Colors.orange,
                child: Column(
                  children: [
                    _buildDangerLevel(
                      level: 'SEGURO',
                      range: '< 1000 ppm',
                      color: Colors.green,
                      description: 'Niveles normales, sin riesgo.',
                    ),
                    _buildDangerLevel(
                      level: 'PRECAUCIÓN',
                      range: '1000 - 2500 ppm',
                      color: Colors.orange,
                      description: 'Niveles elevados, mantente alerta.',
                    ),
                    _buildDangerLevel(
                      level: 'PELIGRO',
                      range: '> 2500 ppm',
                      color: Colors.red,
                      description: 'Niveles críticos, evacúa inmediatamente.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Consejos de seguridad
              _buildSectionCard(
                title: 'Consejos de Seguridad',
                icon: Icons.health_and_safety,
                color: Colors.orange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSafetyTip(
                        'Mantén los sensores limpios y libres de polvo'),
                    _buildSafetyTip('Calibra los sensores regularmente'),
                    _buildSafetyTip('No ignores las alertas del sistema'),
                    _buildSafetyTip('Ventila inmediatamente si hay alarma'),
                    _buildSafetyTip(
                        'Revisa las instalaciones de gas periódicamente'),
                    _buildSafetyTip('Mantén detectores de humo adicionales'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorInfo({
    required String name,
    required String description,
    required String details,
    required String icon,
    required Color color,
    required String ranges,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            icon,
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ranges,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
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
                  fontSize: 16,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerLevel({
    required String level,
    required String range,
    required Color color,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      level,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    Text(
                      range,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
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

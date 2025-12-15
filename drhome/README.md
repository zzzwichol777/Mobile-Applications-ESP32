# DrHome - Sistema Médico Profesional

Sistema médico completo con app Flutter y ESP32 para monitoreo de signos vitales.

## 🏥 Características

### Sensores Médicos
- **MAX30102**: Frecuencia cardíaca y SpO2 (saturación de oxígeno)
- **MLX90614**: Temperatura corporal sin contacto

### Funcionalidades de la App
- ✅ Gestión completa de pacientes
- ✅ Registro de datos personales (edad, peso, estatura, tipo de sangre, alergias)
- ✅ Medición en tiempo real de signos vitales
- ✅ Historial completo de mediciones
- ✅ Diagnósticos automáticos basados en parámetros médicos
- ✅ Cálculo automático de IMC
- ✅ Base de datos local SQLite
- ✅ 4 temas de color (Médico Azul, Océano, Lavanda, Menta)
- ✅ Interfaz moderna y profesional
- ✅ Gráficos de evolución de signos vitales

## 📱 Capturas de Pantalla

La app cuenta con:
- Pantalla de inicio con lista de pacientes
- Formulario completo de registro de pacientes
- Pantalla de medición en tiempo real
- Historial detallado con diagnósticos
- Configuración de ESP32
- Ajustes de tema

## 🔧 Instalación

### Requisitos
- Flutter 3.0 o superior
- Dart 3.0 o superior
- Android Studio / VS Code
- ESP32 con sensores MAX30102 y MLX90614

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
cd drhome_app
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Ejecutar la app**
```bash
flutter run
```

## 🔌 Configuración del ESP32

### Hardware Necesario
- ESP32 DevKit
- Sensor MAX30102 (frecuencia cardíaca y SpO2)
- Sensor MLX90614 (temperatura infrarroja)
- Cables jumper
- Fuente de alimentación

### Conexiones

**MAX30102 (Bus I2C #1)**
- VCC → 3.3V
- GND → GND
- SDA → GPIO 16
- SCL → GPIO 17

**MLX90614 (Bus I2C #2)**
- VCC → 3.3V
- GND → GND
- SDA → GPIO 21
- SCL → GPIO 22

### Librerías Necesarias para ESP32
```cpp
- WiFi.h
- WiFiManager.h
- ESPmDNS.h
- Wire.h
- Adafruit_MLX90614.h
- MAX30105.h
- heartRate.h
- spo2_algorithm.h
- ArduinoJson.h
```

### Cargar el Código
1. Abre `drhome_esp32/drhome_esp32.ino` en Arduino IDE
2. Instala las librerías necesarias desde el Library Manager
3. Selecciona tu placa ESP32
4. Sube el código

### Primera Configuración
1. El ESP32 creará una red WiFi llamada "DrHome"
2. Conéctate a esa red desde tu teléfono
3. Se abrirá un portal de configuración automáticamente
4. Selecciona tu red WiFi y ingresa la contraseña
5. Anota la dirección IP que aparece
6. Ingresa esa IP en la app en Ajustes → Configurar ESP32

## 📊 Uso de la Aplicación

### 1. Agregar un Paciente
- Ve a la pestaña "Pacientes"
- Toca el botón "+"
- Completa los datos del paciente:
  - Nombre completo
  - Edad y género
  - Estatura y peso (opcional, para calcular IMC)
  - Tipo de sangre
  - Alergias
  - Notas adicionales

### 2. Realizar una Medición
- Ve a la pestaña "Medición"
- Asegúrate de que el ESP32 esté conectado (luz verde)
- Selecciona un paciente
- Coloca el dedo índice en el sensor MAX30102
- Toca "Iniciar" y espera 10-15 segundos
- Los valores se actualizarán en tiempo real
- Agrega notas si es necesario
- Toca "Guardar" para registrar la medición

### 3. Ver Historial
- Ve a "Pacientes" y selecciona un paciente
- Verás su información completa y todas sus mediciones
- Toca una medición para ver:
  - Valores detallados
  - Diagnóstico automático
  - Recomendaciones médicas
  - Opción de eliminar

### 4. Cambiar Tema
- Ve a "Ajustes"
- Selecciona uno de los 4 temas disponibles:
  - Médico Azul (predeterminado)
  - Océano (azul turquesa)
  - Lavanda (morado pastel)
  - Menta (verde pastel)

## 🩺 Diagnósticos Automáticos

La app analiza automáticamente:

### Frecuencia Cardíaca
- < 60 BPM: Bradicardia
- 60-100 BPM: Normal
- > 100 BPM: Taquicardia

### Saturación de Oxígeno (SpO2)
- < 90%: Crítico (requiere atención urgente)
- 90-94%: Bajo
- ≥ 95%: Normal

### Temperatura Corporal
- < 35.0°C: Hipotermia
- 35.0-36.4°C: Baja
- 36.5-37.4°C: Normal
- 37.5-37.9°C: Febrícula
- ≥ 38.0°C: Fiebre

### IMC (Índice de Masa Corporal)
- < 18.5: Bajo peso
- 18.5-24.9: Normal
- 25.0-29.9: Sobrepeso
- ≥ 30.0: Obesidad

## ⚠️ Aviso Médico Importante

**DrHome es un sistema de monitoreo diseñado con fines educativos y de seguimiento personal.**

- Los diagnósticos automáticos son orientativos
- NO reemplaza la consulta médica profesional
- En caso de emergencia, contacte servicios médicos inmediatamente
- Los sensores deben estar calibrados correctamente
- Consulte con su médico antes de tomar decisiones basadas en estas mediciones
- Este dispositivo NO está certificado como equipo médico profesional

## 🛠️ Solución de Problemas

### La app no se conecta al ESP32
- Verifica que el ESP32 esté encendido
- Confirma que ambos dispositivos estén en la misma red WiFi
- Prueba usar la IP en lugar de drhome.local
- Reinicia el ESP32

### El sensor MAX30102 no detecta el dedo
- Asegúrate de colocar el dedo correctamente
- Limpia el sensor
- Verifica las conexiones I2C
- El dedo debe cubrir completamente el sensor

### Lecturas incorrectas
- Mantén el dedo quieto durante la medición
- Espera al menos 10-15 segundos
- Evita mover el brazo
- Asegúrate de que el sensor esté bien conectado

### El ESP32 no se conecta a WiFi
- Usa "Olvidar WiFi" en la app
- Reinicia el ESP32
- Vuelve a configurar la red WiFi

## 📦 Estructura del Proyecto

```
drhome_app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── patient.dart
│   │   └── measurement.dart
│   ├── providers/
│   │   ├── theme_provider.dart
│   │   ├── patient_provider.dart
│   │   └── esp32_provider.dart
│   ├── database/
│   │   └── database_helper.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── home_screen.dart
│   │   ├── patients_list_screen.dart
│   │   ├── add_patient_screen.dart
│   │   ├── patient_detail_screen.dart
│   │   ├── measurement_screen.dart
│   │   ├── esp32_config_screen.dart
│   │   └── settings_screen.dart
│   └── utils/
│       └── theme.dart
└── pubspec.yaml

drhome_esp32/
└── drhome_esp32.ino
```

## 🎨 Diseño

La app sigue las mejores prácticas de diseño iOS/Android con:
- Material Design 3
- Navegación intuitiva con bottom navigation
- Cards con elevación y sombras suaves
- Colores pasteles profesionales
- Iconografía médica clara
- Feedback visual en todas las acciones
- Animaciones suaves

## 📝 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 👨‍⚕️ Créditos

Desarrollado como sistema médico educativo basado en ESP32 y Flutter.

---

**¿Preguntas o problemas?** Abre un issue en el repositorio.

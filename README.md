# 📱 Mobile Applications - IoT con ESP32 y Flutter

Colección de aplicaciones móviles desarrolladas en Flutter que se conectan con dispositivos ESP32 para monitoreo de sensores en tiempo real.

## 🚀 Proyectos

### 🏥 DrHome - Sistema Médico
Sistema médico profesional para monitoreo de signos vitales.

**Sensores:**
- MAX30102: Frecuencia cardíaca y SpO2 (saturación de oxígeno)
- MLX90614: Temperatura corporal sin contacto

**Características:**
- Gestión completa de pacientes (edad, peso, estatura, tipo de sangre, alergias)
- Medición en tiempo real de signos vitales
- Historial de mediciones con diagnósticos automáticos
- Cálculo de IMC
- Base de datos local SQLite
- 4 temas de color personalizables
- Gráficos de evolución de signos vitales

📁 [Ver proyecto DrHome](./drhome/)

---

### 🌡️ FersXMeT - Estación Meteorológica
Estación meteorológica completa con análisis ambiental avanzado.

**Sensores:**
- MLX90614: Sensor térmico infrarrojo (temperatura ambiente y objeto)
- DHT22: Temperatura (-40 a 80°C) y humedad (0-100%)
- BH1750: Luminosidad (1-65535 lux)

**Características:**
- Monitoreo en tiempo real de temperatura, humedad y luminosidad
- Gráficos comparativos de temperatura dual (DHT22 vs MLX90614)
- Análisis de temperatura de objeto vs temperatura ambiental
- Cálculo de sensación térmica (Heat Index)
- Base de datos local con historial y geolocalización
- 10 temas de colores pastel
- Sistema de notificaciones y alertas

📁 [Ver proyecto FersXMeT](./fersxmet/)

---

### 🔥 Gasox - Detector de Gases
Sistema detector de humos y gases peligrosos con alertas en tiempo real.

**Sensores:**
- MQ4: Detector de metano y gas natural
- MQ7: Detector de monóxido de carbono (CO)
- Buzzer + LED: Indicadores de alarma

**Características:**
- Monitoreo en tiempo real de niveles de gas
- Umbrales configurables para cada sensor
- Sistema de alarma con sonido, vibración y notificaciones
- Base de datos con historial de lecturas
- Geolocalización de lecturas
- Guardado automático cuando se detecta gas peligroso
- Interfaz oscura con tema naranja

📁 [Ver proyecto Gasox](./gasox/)

---

## 🔌 Códigos ESP32

Los códigos para los microcontroladores ESP32 se encuentran en la carpeta `ESP32 - Codes/`:
- `DRHOME/` - Código para el sistema médico
- `FERSXMET/` - Código para la estación meteorológica
- `GASOX/` - Código para el detector de gases

---

## 📸 Multimedia

### Screenshots
- `DrHome Screenshot.jpg` - Captura de pantalla de la aplicación DrHome

### Videos Demostrativos
- `Record FersXMeT.mp4` - Demostración de la app FersXMeT en funcionamiento
- `Record Gasox.mp4` - Demostración de la app Gasox en funcionamiento

---

## 🛠️ Tecnologías

- **Framework:** Flutter 3.x
- **Lenguaje:** Dart
- **Base de Datos:** SQLite (sqflite)
- **Hardware:** ESP32 DevKit
- **Comunicación:** HTTP REST / WiFi
- **Sensores:** MAX30102, MLX90614, DHT22, BH1750, MQ4, MQ7

---

## 📋 Requisitos

### App Móvil
- Android 5.0 (API 21) o superior
- Flutter 3.0 o superior

### Hardware
- ESP32 DevKit
- Sensores correspondientes a cada proyecto
- Fuente de alimentación 3.3V

---

## 👨‍💻 Autor

Desarrollado como proyectos IoT educativos con ESP32 y Flutter.

---

## 📄 Licencia

Proyectos de código abierto para fines educativos.

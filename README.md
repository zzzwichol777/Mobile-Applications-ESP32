# 📱 Mobile Applications - IoT con ESP32 y Flutter

Colección de aplicaciones móviles desarrolladas en Flutter que se conectan con dispositivos ESP32 para monitoreo de sensores en tiempo real.

---

## 🔥 Gasox - Detector de Gases

Sistema detector de humos y gases peligrosos con alertas en tiempo real.

**Sensores:** MQ4 (metano), MQ7 (CO), Buzzer + LED

| GUI Principal | Sistema de Alarma |
|:---:|:---:|
| ![GASOX GUI](GASOX%20GUI%20Principal.gif) | ![GASOX Alarma](GASOX%20ALARMA.gif) |

| Base de Datos | Información del Sistema |
|:---:|:---:|
| ![GASOX DB](GASOX%20BASE%20DE%20DATOS.gif) | ![GASOX Info](GASOX%20Información%20del%20Sistema.gif) |

📁 [Ver proyecto Gasox](./gasox/)

---

## 🌡️ FersXMeT - Estación Meteorológica

Estación meteorológica completa con análisis ambiental avanzado.

**Sensores:** MLX90614 (térmico IR), DHT22 (temp/humedad), BH1750 (luminosidad)

| GUI Principal | Temas |
|:---:|:---:|
| ![FERSXMET GUI](FERSXMET%20GUI.gif) | ![FERSXMET Temas](FERSXMET%20TEMAS.gif) |

| Gráficas Comparativas | Análisis Ambiental |
|:---:|:---:|
| ![FERSXMET Graficas](FERSXMET%20GRÁFICAS%20COMPARATIVAS.gif) | ![FERSXMET Analisis](FERSXMET%20ANÁLISIS%20AMBIENTAL.gif) |

| Alertas |
|:---:|
| ![FERSXMET Alertas](FERSXMET%20ALERTAS.gif) |

📁 [Ver proyecto FersXMeT](./fersxmet/)

---

## 🏥 DrHome - Sistema Médico

Sistema médico profesional para monitoreo de signos vitales.

**Sensores:** MAX30102 (frecuencia cardíaca y SpO2), MLX90614 (temperatura corporal)

**Características:**
- Gestión completa de pacientes (edad, peso, estatura, tipo de sangre, alergias)
- Medición en tiempo real de signos vitales
- Historial de mediciones con diagnósticos automáticos
- Cálculo de IMC
- Base de datos local SQLite
- 4 temas de color personalizables

📁 [Ver proyecto DrHome](./drhome/)

---

## 🔌 Códigos ESP32

Los códigos para los microcontroladores ESP32 se encuentran en la carpeta `ESP32 - Codes/`:
- `DRHOME/` - Código para el sistema médico
- `FERSXMET/` - Código para la estación meteorológica
- `GASOX/` - Código para el detector de gases

---

## 🛠️ Tecnologías

| Categoría | Tecnología |
|-----------|------------|
| Framework | Flutter 3.x |
| Lenguaje | Dart |
| Base de Datos | SQLite (sqflite) |
| Hardware | ESP32 DevKit |
| Comunicación | HTTP REST / WiFi |
| Sensores | MAX30102, MLX90614, DHT22, BH1750, MQ4, MQ7 |

---

## 📋 Requisitos

**App Móvil:** Android 5.0+ / Flutter 3.0+

**Hardware:** ESP32 DevKit + sensores correspondientes + fuente 3.3V

---

## 📄 Licencia

Proyectos de código abierto para fines educativos.

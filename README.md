# 📱 Mobile Applications ESP32

<div align="center">

**Aplicaciones móviles desarrolladas en Flutter para conectarse con microcontroladores ESP32 y recibir información de sensores en tiempo real.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![ESP32](https://img.shields.io/badge/ESP32-IoT-E7352C?logo=espressif)](https://www.espressif.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## 📖 Descripción

Este repositorio contiene una colección de aplicaciones móviles IoT que se comunican vía WiFi con dispositivos ESP32 equipados con diversos sensores. Cada aplicación está diseñada para un propósito específico: monitoreo médico, estación meteorológica y detección de gases peligrosos.

**Características comunes:**
- �V Comunicación HTTP REST con ESP32
- 💾 Base de datos local SQLite para historial
- 🎨 Múltiples temas personalizables
- 📍 Geolocalización de lecturas
- 🔔 Sistema de notificaciones y alertas
- ⚙️ Configuración de red flexible

---

## 🔥 GASOX - Detector de Gases

Sistema detector de humos y gases peligrosos con alertas en tiempo real.

**Sensores:** MQ4 (metano/gas natural) • MQ7 (monóxido de carbono) • Buzzer + LED

| GUI Principal | Sistema de Alarma |
|:---:|:---:|
| ![GASOX GUI](Preview/GASOX%20GUI%20Principal.gif) | ![GASOX Alarma](Preview/GASOX%20ALARMA.gif) |

| Base de Datos | Información del Sistema |
|:---:|:---:|
| ![GASOX DB](Preview/GASOX%20BASE%20DE%20DATOS.gif) | ![GASOX Info](Preview/GASOX%20Información%20del%20Sistema.gif) |

**Funcionalidades:**
- Monitoreo en tiempo real de niveles de gas
- Umbrales configurables para cada sensor
- Alarma con sonido, vibración y notificaciones push
- Guardado automático al detectar gas peligroso

📁 [Ver código fuente](./gasox/)

---

## 🌡️ FERSXMET - Estación Meteorológica

Estación meteorológica completa con análisis ambiental avanzado y gráficas comparativas.

**Sensores:** MLX90614 (térmico infrarrojo) • DHT22 (temperatura/humedad) • BH1750 (luminosidad)

| GUI Principal | Selector de Temas |
|:---:|:---:|
| ![FERSXMET GUI](Preview/FERSXMET%20GUI.gif) | ![FERSXMET Temas](Preview/FERSXMET%20TEMAS.gif) |

| Gráficas Comparativas | Análisis Ambiental |
|:---:|:---:|
| ![FERSXMET Graficas](Preview/FERSXMET%20GRÁFICAS%20COMPARATIVAS.gif) | ![FERSXMET Analisis](Preview/FERSXMET%20ANÁLISIS%20AMBIENTAL.gif) |

| Sistema de Alertas |
|:---:|
| ![FERSXMET Alertas](Preview/FERSXMET%20ALERTAS.gif) |

**Funcionalidades:**
- Gráficos comparativos de temperatura dual (DHT22 vs MLX90614)
- Análisis de temperatura de objeto vs temperatura ambiental
- Cálculo de sensación térmica (Heat Index)
- 10 temas de colores pastel

📁 [Ver código fuente](./fersxmet/)

---

## 🏥 DRHOME - Sistema Médico

Sistema médico profesional para monitoreo de signos vitales con diagnósticos automáticos.

**Sensores:** MAX30102 (frecuencia cardíaca y SpO2) • MLX90614 (temperatura corporal sin contacto)

<div align="center">

![DrHome Screenshot](Preview/DrHome%20Screen.jpg)

</div>

**Funcionalidades:**
- Gestión completa de pacientes (edad, peso, estatura, tipo de sangre, alergias)
- Medición en tiempo real de signos vitales
- Historial de mediciones con diagnósticos automáticos
- Cálculo de IMC
- 4 temas de color personalizables
- Gráficos de evolución de signos vitales

📁 [Ver código fuente](./drhome/)

---

## 🚁 Ejemplo de Aplicación: Drone Meteorológico

Combinación de **GASOX + FERSXMET** montados en un drone para monitoreo ambiental aéreo, detectando gases peligrosos y condiciones meteorológicas en tiempo real.

| Drone con GASOX | Drone con FERSXMET |
|:---:|:---:|
| ![Drone GASOX](Preview/Drone%20With%20GASOX.jpg) | ![Drone FERSXMET](Preview/Drone%20With%20FERSXMET.jpg) |

**Aplicaciones potenciales:**
- 🏭 Monitoreo industrial de emisiones
- 🌾 Agricultura de precisión
- 🔥 Detección temprana de incendios
- 🌍 Estudios ambientales

---

## 🔌 Códigos ESP32

Los códigos para los microcontroladores se encuentran en [`ESP32 - Codes/`](./ESP32%20-%20Codes/):

| Proyecto | Archivo | Sensores |
|----------|---------|----------|
| DRHOME | `DRHOME.ino` | MAX30102, MLX90614 |
| FERSXMET | `FERSXMET.ino` | MLX90614, DHT22, BH1750 |
| GASOX | `GASOX.ino` | MQ4, MQ7, Buzzer, LED |
| Combinado | `Sistema Meteorológico y de Gases COMBINADO.ino` | Todos los sensores |

---

## 🛠️ Stack Tecnológico

| Categoría | Tecnología |
|-----------|------------|
| **Framework** | Flutter 3.x |
| **Lenguaje** | Dart |
| **Base de Datos** | SQLite (sqflite) |
| **Hardware** | ESP32 DevKit |
| **Comunicación** | HTTP REST / WiFi |
| **Sensores** | MAX30102, MLX90614, DHT22, BH1750, MQ4, MQ7 |

---

## 📋 Requisitos

### Software
- Flutter 3.0+
- Android 5.0 (API 21) o superior
- Arduino IDE (para ESP32)

### Hardware
- ESP32 DevKit
- Sensores correspondientes a cada proyecto
- Fuente de alimentación 3.3V

---

## 🚀 Instalación

```bash
# Clonar repositorio
git clone https://github.com/zzzwichol777/Mobile-Applications.git

# Entrar a cualquier proyecto
cd gasox  # o fersxmet, drhome

# Instalar dependencias
flutter pub get

# Ejecutar
flutter run
```

---

## 📄 Licencia

Proyectos de código abierto para fines educativos bajo licencia MIT.

---

<div align="center">

**Desarrollado con ❤️ por José Luis OP**

</div>

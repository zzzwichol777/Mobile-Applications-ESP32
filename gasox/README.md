# 🔥 GASOX - Sistema Detector de Gases con ESP32

Sistema detector de humos y gases peligrosos con alertas en tiempo real, desarrollado con Flutter y ESP32.

## 📱 Descripción

GASOX es una aplicación móvil que se conecta con un ESP32 equipado con sensores MQ4 y MQ7 para detectar niveles peligrosos de metano y monóxido de carbono. Incluye un sistema de alarma completo con buzzer, LED, notificaciones push, sonido y vibración.

---

## 🎯 Características

### 📊 Monitoreo en Tiempo Real
- Lectura continua de sensores MQ4 (metano) y MQ7 (CO)
- Actualización cada 2 segundos
- Indicador visual de conexión WiFi

### ⚠️ Sistema de Alarma
- Umbrales configurables para cada sensor
- Alarma sonora con 3 sonidos predefinidos + sonido personalizado
- Vibración del dispositivo
- Notificaciones push incluso en segundo plano
- Animación visual de alerta
- Buzzer y LED en el ESP32

### 💾 Base de Datos
- Historial completo de lecturas
- Guardado automático al detectar gas peligroso
- Guardado manual con un toque
- Geolocalización de cada lectura

### 🌍 Geolocalización
- Registro de ubicación en cada lectura
- Pantalla dedicada para lecturas con ubicación
- Coordenadas GPS precisas

### ⚙️ Configuración
- Ajuste de IP y puerto del ESP32
- Configuración de umbrales de alarma
- Volumen de alarma ajustable
- Activar/desactivar sonido, vibración y notificaciones
- Selección de sonido de alarma

---

## 🔧 Hardware Necesario

### Componentes
- ESP32 DevKit
- Sensor MQ4 (metano/gas natural)
- Sensor MQ7 (monóxido de carbono)
- Buzzer activo
- LED rojo
- Resistencias y cables

### Conexiones
```
MQ4:    AO → GPIO 34 (ADC)
MQ7:    AO → GPIO 35 (ADC)
Buzzer: + → GPIO 25
LED:    + → GPIO 26 (con resistencia 220Ω)
```

---

## 📱 Pantallas de la App

### 🏠 Pantalla Principal
- Tarjetas de sensores MQ4 y MQ7 con valores en tiempo real
- Indicador de umbral y estado de alarma
- Widget de ubicación actual
- Controles de umbrales
- Botón para guardar lectura

### 🔔 Notificaciones
- Activar/desactivar notificaciones
- Activar/desactivar sonido
- Activar/desactivar vibración
- Selección de sonido de alarma
- Ajuste de volumen
- Sonido personalizado desde archivos

### 📡 Configuración de Red
- IP del ESP32
- Puerto de conexión
- Test de conexión

### 💾 Base de Datos
- Historial de todas las lecturas
- Filtrado por fecha
- Indicador de lecturas con alarma activa

### 📍 Lecturas con Ubicación
- Lista de lecturas con coordenadas GPS
- Fecha, hora y valores de sensores

### ℹ️ Acerca de
- Información del sistema
- Versión de la app

---

## 🚀 Instalación

### App Flutter
```bash
cd gasox
flutter pub get
flutter run
```

### ESP32
1. Abre el código en Arduino IDE
2. Instala las librerías necesarias
3. Configura tu red WiFi
4. Sube el código al ESP32
5. Anota la IP que aparece en el Serial Monitor

### Primera Conexión
1. Abre la app GASOX
2. Ve a Configuración de Red
3. Ingresa la IP del ESP32
4. Guarda y verifica la conexión

---

## 📊 Especificaciones

### Sensores
| Sensor | Gas Detectado | Rango |
|--------|---------------|-------|
| MQ4 | Metano, Gas Natural | 200-10000 ppm |
| MQ7 | Monóxido de Carbono | 20-2000 ppm |

### App
- **Plataforma:** Android 5.0+
- **Framework:** Flutter 3.x
- **Base de Datos:** SQLite
- **Comunicación:** HTTP REST

---

## ⚠️ Aviso de Seguridad

Este sistema es un proyecto educativo y NO debe usarse como único sistema de detección de gases en situaciones de riesgo real. Para protección profesional, utilice detectores certificados.

---

## 📄 Licencia

Proyecto de código abierto para fines educativos.

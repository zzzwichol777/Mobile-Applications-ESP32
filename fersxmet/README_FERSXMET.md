# 🌡️ FERSXMET - Estación Meteorológica con ESP32

## 📱 Estado del Proyecto: ✅ LISTO PARA USAR

**APK Compilado**: `build\app\outputs\flutter-apk\app-release.apk` (45.9 MB)  
**Versión**: 1.0.0  
**Package**: com.example.fersxmet

---

## 🚀 Inicio Rápido

### 1. Instalar la App (2 minutos)

**Opción A: Usando ADB**
```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

**Opción B: Manual**
1. Copia el APK a tu dispositivo Android
2. Abre el archivo y toca "Instalar"
3. Acepta los permisos de ubicación

### 2. Configurar ESP32 (30 minutos)

Ver instrucciones detalladas en: `FERSXMET_SETUP.md`

**Hardware necesario**:
- ESP32
- Sensor MLX90614 (sensor térmico infrarrojo)
- Sensor DHT22 (temperatura/humedad)
- Sensor BH1750 (luminosidad)

**Conexiones rápidas**:
```
MLX90614: SDA→21, SCL→22, VCC→3.3V, GND→GND
DHT22:    DATA→4, VCC→3.3V, GND→GND
BH1750:   SDA→21, SCL→22, VCC→3.3V, GND→GND
```

### 3. Conectar App con ESP32 (1 minuto)

1. Abre la app FERSXMET
2. Ve a ⚙️ Configuración de Red
3. Ingresa la IP del ESP32 (visible en Serial Monitor)
4. Toca "Guardar"
5. ¡Listo! Ya puedes ver las lecturas

---

## 📚 Documentación Completa

| Documento | Descripción |
|-----------|-------------|
| `COMPILACION_EXITOSA.md` | Cómo instalar el APK y troubleshooting |
| `FERSXMET_SETUP.md` | Configuración completa del ESP32 |
| `CAMBIOS_REALIZADOS.md` | Resumen de todos los cambios aplicados |
| `CHECKLIST_FERSXMET.md` | Lista de verificación del proyecto |
| `CONFIGURACION_ENTORNO.md` | Configuración del entorno de desarrollo |

---

## ✨ Características

### 📊 Monitoreo en Tiempo Real
- 🌡️ Temperatura y humedad (DHT22)
- 💡 Luminosidad ambiental (BH1750)
- 🔥 Sensor térmico infrarrojo (MLX90614)
- 📍 Geolocalización de lecturas

### 📈 Gráficos de Temperatura Dual (NUEVO)
- 📉 Gráfico en tiempo real del DHT22 (temperatura ambiente)
- 📉 Gráfico dual del MLX90614 (temperatura ambiente + objeto)
- 📊 Comparación DHT22 vs MLX90614
- ⏱️ Historial de hasta 30 puntos de datos
- 🎯 Tooltips interactivos con valores exactos

### 💾 Base de Datos Local
- Guarda todas las lecturas automáticamente
- Historial completo con fecha, hora y ubicación
- Búsqueda y filtrado de datos

### 🎨 Personalización
- 10 temas de colores pastel
- Interfaz moderna y responsive
- Modo oscuro optimizado

### 🌐 Conectividad
- Conexión WiFi con ESP32
- Configuración de red flexible
- Detección automática de conectividad

---

## 📈 Gráficos de Temperatura Dual

### Descripción
La nueva funcionalidad de gráficos permite visualizar en tiempo real las mediciones de temperatura de los sensores DHT22 y MLX90614, facilitando el análisis comparativo y la detección de anomalías térmicas.

### Sensores Utilizados

| Sensor | Medición | Uso Principal |
|--------|----------|---------------|
| **DHT22** | Temperatura ambiente | Monitoreo ambiental general |
| **MLX90614 (Ambiente)** | Temperatura ambiente IR | Referencia térmica infrarroja |
| **MLX90614 (Objeto)** | Temperatura de objeto | Detección de objetos calientes/fríos |

### Tipos de Gráficos

1. **Gráfico DHT22**: Muestra la evolución de la temperatura ambiente medida por el sensor DHT22.

2. **Gráfico MLX90614 Dual**: Visualiza simultáneamente la temperatura ambiente y la temperatura del objeto detectado por el sensor infrarrojo.

3. **Gráfico Comparativo**: Compara las lecturas del DHT22 con el MLX90614 para validar mediciones y detectar discrepancias.

### Características de los Gráficos
- Actualización cada 3 segundos
- Historial de hasta 30 puntos de datos
- Líneas suavizadas con curvas Bézier
- Área sombreada bajo las curvas
- Tooltips interactivos al tocar
- Leyenda de colores identificativa
- Escala automática según valores

### Cómo Usar
1. Desde la pantalla principal, toca el ícono de gráficos (📈)
2. Presiona "Iniciar" para comenzar la grabación
3. Observa cómo se van graficando las temperaturas
4. Usa "Detener" para pausar y "Limpiar" para reiniciar

---

## 🎯 Casos de Uso

### 🏠 Hogar
- Monitoreo de temperatura y humedad en habitaciones
- Control de iluminación natural
- Detección de fugas de calor

### 🌱 Agricultura
- Monitoreo de condiciones en invernaderos
- Control de riego basado en humedad
- Optimización de luz para plantas

### 🏭 Industrial
- Monitoreo de equipos con cámara térmica
- Detección de puntos calientes
- Control de condiciones ambientales

### 🔬 Educación
- Experimentos de física y química
- Proyectos de IoT
- Aprendizaje de sensores y microcontroladores

---

## 🛠️ Tecnologías Utilizadas

### App Móvil
- **Framework**: Flutter 3.35.6
- **Lenguaje**: Dart
- **Base de Datos**: SQLite (sqflite)
- **Geolocalización**: Geolocator
- **UI**: Material Design 3

### Hardware
- **Microcontrolador**: ESP32
- **Sensores**:
  - MLX90614: Sensor térmico infrarrojo (temperatura ambiente y objeto)
  - DHT22: Temperatura (-40 a 80°C) y humedad (0-100%)
  - BH1750: Luminosidad (1-65535 lux)

### Comunicación
- **Protocolo**: HTTP REST
- **Puerto**: 8080
- **Formato**: JSON

---

## 📱 Pantallas de la Aplicación

### 🏠 Pantalla Principal
- Lecturas en tiempo real de todos los sensores
- Tarjetas de temperatura ambiente (DHT22) y humedad
- Tarjeta de luminosidad con indicador de nivel
- Sensor térmico IR con temperatura ambiente y objeto
- Cálculo de sensación térmica (Heat Index)
- Botón para guardar lecturas en la base de datos

### 📈 Gráficos de Temperatura
- Gráfico del DHT22 (temperatura ambiente)
- Gráfico dual del MLX90614 (ambiente + objeto)
- Gráfico comparativo entre sensores
- Controles de inicio/pausa y limpieza de datos
- Indicador de estado de conexión

### 💾 Historial de Lecturas
- Lista de todas las lecturas guardadas
- Filtrado por fecha
- Detalles de cada lectura con ubicación
- Exportación de datos

### ⚙️ Configuración de Red
- Ajuste de IP del ESP32
- Configuración de puerto
- Test de conexión

### 🎨 Selector de Temas
- 10 temas de colores pastel
- Vista previa en tiempo real
- Persistencia de preferencias

### 🔔 Notificaciones
- Alertas de temperatura alta/baja
- Alertas de humedad
- Configuración de umbrales

---

## 🔧 Desarrollo

### Compilar desde Código Fuente

```bash
# Clonar el repositorio
cd fersxmet

# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run

# Compilar APK release
flutter build apk --release
```

### Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
└── fersxmet/
    ├── models/                  # Modelos de datos
    │   └── weather_reading.dart
    ├── screens/                 # Pantallas de la app
    │   ├── weather_home_screen_new.dart    # Pantalla principal
    │   ├── weather_database_screen.dart    # Historial de lecturas
    │   ├── weather_network_settings_screen.dart
    │   ├── weather_splash_screen.dart
    │   ├── theme_selector_screen.dart
    │   ├── notifications_settings_screen.dart
    │   └── temperature_charts_screen.dart  # Gráficos de temperatura
    ├── services/                # Servicios
    │   ├── esp32_weather_service.dart      # Comunicación con ESP32
    │   ├── weather_database_service.dart   # Base de datos SQLite
    │   ├── weather_location_service.dart   # Geolocalización
    │   └── notification_service.dart       # Notificaciones
    ├── utils/                   # Utilidades
    │   └── theme_manager.dart              # Gestión de temas
    └── widgets/                 # Widgets personalizados
        ├── heat_map_widget.dart
        └── temperature_chart_widget.dart   # Widget de gráficos
```

---

## 🐛 Troubleshooting

### App no se conecta al ESP32
1. Verifica que ambos estén en la misma red WiFi
2. Comprueba la IP del ESP32 en el Serial Monitor
3. Intenta hacer ping: `ping [IP_DEL_ESP32]`

### Sensor no responde
1. Verifica las conexiones físicas
2. Usa un I2C scanner para detectar dispositivos
3. Revisa la alimentación (debe ser 3.3V)

### Mapa de calor no se muestra
1. El MLX90640 tarda unos segundos en inicializar
2. Verifica que la respuesta JSON tenga 768 elementos
3. Comprueba que el sensor esté correctamente conectado

### Ubicación no disponible
1. Acepta los permisos de ubicación
2. Activa el GPS en tu dispositivo
3. Sal al exterior o acércate a una ventana

---

## 📊 Especificaciones Técnicas

### Requisitos de la App
- **Android**: 5.0 (API 21) o superior
- **Espacio**: 100 MB mínimo
- **RAM**: 2 GB recomendado
- **Permisos**: Internet, Ubicación, WiFi

### Requisitos del ESP32
- **Voltaje**: 3.3V
- **Corriente**: 500mA mínimo (con todos los sensores)
- **WiFi**: 2.4 GHz (802.11 b/g/n)
- **Memoria**: 4 MB Flash mínimo

### Rendimiento
- **Frecuencia de lectura**: 1 segundo
- **Latencia de red**: < 100ms (red local)
- **Precisión DHT22**: ±0.5°C, ±2% HR
- **Precisión BH1750**: ±20%
- **Precisión MLX90614**: ±0.5°C (objeto), ±0.5°C (ambiente)
- **Rango MLX90614**: -40°C a 125°C (ambiente), -70°C a 380°C (objeto)

---

## 🤝 Contribuir

Este es un proyecto educativo. Siéntete libre de:
- Reportar bugs
- Sugerir mejoras
- Agregar nuevos sensores
- Mejorar la interfaz

---

## 📄 Licencia

Este proyecto es de código abierto para fines educativos.

---

## 👨‍💻 Autor

Proyecto FERSXMET - Estación Meteorológica con ESP32

---

## 🎉 ¡Gracias por usar FERSXMET!

Si tienes preguntas o problemas, revisa la documentación en los archivos MD incluidos.

**¡Disfruta monitoreando el clima con tu estación meteorológica!** 🌤️

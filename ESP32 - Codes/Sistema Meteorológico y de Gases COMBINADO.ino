/*
 * ESP32 UNIFICADO - GASOX + FERSXMET
 * 
 * Sistema combinado que maneja:
 * - GASOX: Sensores de gas MQ4 y MQ7 con alarma
 * - FERSXMET: Sensores meteorológicos (MLX90614, DHT22, BH1750)
 * 
 * Ambas apps pueden conectarse al mismo ESP32 en el puerto 8080
 */

#include <WiFi.h>
#include <WiFiManager.h>
#include <ESPmDNS.h>
#include <Preferences.h>
#include <Wire.h>
#include <Adafruit_MLX90614.h>
#include <DHT.h>
#include <BH1750.h>
#include <ArduinoJson.h>

// ==================== CONFIGURACIÓN GASOX ====================

const int MQ4_PIN = 34;
const int MQ7_PIN = 35;

// ==================== CONFIGURACIÓN FERSXMET ====================
#define DHT_PIN 4
#define DHT_TYPE DHT22
#define I2C1_SDA 16
#define I2C1_SCL 17
#define I2C2_SDA 21
#define I2C2_SCL 22

// ==================== CONFIGURACIÓN GENERAL ====================
#define SERVER_PORT 8080
#define WIFI_SSID "ESP32_UNIFIED"

// ==================== OBJETOS GLOBALES ====================
WiFiServer server(SERVER_PORT);
Preferences preferences;

// FERSXMET - Sensores
TwoWire I2C_MLX = TwoWire(0);
TwoWire I2C_BH1750 = TwoWire(1);
Adafruit_MLX90614 mlx = Adafruit_MLX90614();
DHT dht(DHT_PIN, DHT_TYPE);
BH1750 lightMeter;

// ==================== VARIABLES DE ESTADO ====================
// GASOX
int mq4Threshold = 3000;
int mq7Threshold = 3000;
bool alarmState = false;
bool ledState = false;
unsigned long lastBlinkTime = 0;
const unsigned long BLINK_INTERVAL = 500;

// FERSXMET
bool mlxAvailable = false;
bool dhtAvailable = false;
bool bh1750Available = false;

// General
unsigned long lastReadingTime = 0;
const unsigned long READING_INTERVAL = 5000;

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n╔════════════════════════════════════════════╗");
  Serial.println("║   ESP32 UNIFICADO - GASOX + FERSXMET      ║");
  Serial.println("╚════════════════════════════════════════════╝\n");
  
  
  // Cargar configuración GASOX
  preferences.begin("gasox", true);
  mq4Threshold = preferences.getInt("mq4_thresh", 3000);
  mq7Threshold = preferences.getInt("mq7_thresh", 3000);
  preferences.end();
  Serial.println("✓ GASOX - Umbrales cargados:");
  Serial.println("  - MQ4: " + String(mq4Threshold));
  Serial.println("  - MQ7: " + String(mq7Threshold));
  
  // Inicializar buses I2C para FERSXMET
  Serial.println("\n✓ Inicializando buses I2C...");
  I2C_MLX.begin(I2C1_SDA, I2C1_SCL, 100000);
  I2C_BH1750.begin(I2C2_SDA, I2C2_SCL, 400000);
  Serial.println("  - Bus I2C #1 (MLX90614): SDA=" + String(I2C1_SDA) + ", SCL=" + String(I2C1_SCL));
  Serial.println("  - Bus I2C #2 (BH1750):   SDA=" + String(I2C2_SDA) + ", SCL=" + String(I2C2_SCL));
  
  // Escanear y inicializar sensores FERSXMET
  scanI2C();
  initSensors();
  
  // Configurar WiFi
  setupWiFi();
  
  // Iniciar mDNS
  if (MDNS.begin("gasox")) {
    MDNS.addService("http", "tcp", SERVER_PORT);
    Serial.println("✓ mDNS iniciado: gasox.local");
  }
  
  // Iniciar servidor
  server.begin();
  Serial.println("\n✓ Servidor iniciado en puerto " + String(SERVER_PORT));
  Serial.println("✓ Sistema listo - Esperando conexiones...\n");
}

// ==================== LOOP PRINCIPAL ====================
void loop() {
  // Leer sensores GASOX y manejar alarma
  int mq4Value = analogRead(MQ4_PIN);
  int mq7Value = analogRead(MQ7_PIN);
  bool shouldAlarm = (mq4Value > mq4Threshold) || (mq7Value > mq7Threshold);
  
  if (shouldAlarm != alarmState) {
    alarmState = shouldAlarm;
    Serial.println(alarmState ? "⚠️  ALARMA ACTIVADA" : "✓ Alarma desactivada");
  }
  
  activateAlarm(alarmState);
  
  // Mostrar lecturas periódicas
  if (millis() - lastReadingTime >= READING_INTERVAL) {
    lastReadingTime = millis();
    printAllReadings(mq4Value, mq7Value);
  }
  
  // Manejar clientes
  WiFiClient client = server.available();
  if (client) {
    Serial.println("\n>>> Cliente conectado <<<");
    
    while (client.connected()) {
      if (client.available()) {
        String command = client.readStringUntil('\n');
        command.trim();
        
        if (command.length() > 0) {
          Serial.println("Comando: " + command);
          handleCommand(client, command);
          client.flush();
          break;
        }
      }
    }
    
    delay(10);
    client.stop();
    Serial.println(">>> Cliente desconectado <<<\n");
  }
  
  delay(100);
}

// ==================== INICIALIZACIÓN ====================
void initSensors() {
  Serial.println("\n✓ Inicializando sensores FERSXMET...");
  
  // MLX90614
  Serial.print("  - MLX90614: ");
  if (mlx.begin(0x5A, &I2C_MLX)) {
    mlxAvailable = true;
    Serial.println("OK");
  } else {
    Serial.println("No detectado");
  }
  
  // DHT22
  Serial.print("  - DHT22: ");
  dht.begin();
  delay(2000);
  float testTemp = dht.readTemperature();
  if (!isnan(testTemp)) {
    dhtAvailable = true;
    Serial.println("OK");
  } else {
    Serial.println("No responde");
  }
  
  // BH1750
  Serial.print("  - BH1750: ");
  if (lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE, 0x23, &I2C_BH1750)) {
    bh1750Available = true;
    Serial.println("OK");
  } else {
    Serial.println("No detectado");
  }
}

void setupWiFi() {
  Serial.println("\n✓ Configurando WiFi...");
  
  WiFiManager wm;
  wm.setConfigPortalTimeout(180);
  
  // Estilo naranja para el portal
  wm.setCustomHeadElement(
    "<style>"
    "body{background-color:#222;}"
    "h1,h2,h3,label,legend,span,div,td,th,p,a{color:#FFA500!important;}"
    "button,input[type='submit'],.btn{background-color:#FFA500!important;color:#222!important;font-weight:bold;}"
    "input,select{background-color:#333!important;color:#FFA500!important;border:1px solid #FFA500!important;}"
    ".msg{color:#FFA500!important;}"
    "</style>"
  );
  
  wm.setAPCallback([](WiFiManager* wm) {
    Serial.println("Modo AP: Conéctate a " + String(WIFI_SSID));
  });
  
  if (!wm.autoConnect(WIFI_SSID)) {
    Serial.println("Error de conexión, reiniciando...");
    delay(3000);
    ESP.restart();
  }
  
  Serial.println("✓ WiFi conectado!");
  Serial.println("  - SSID: " + WiFi.SSID());
  Serial.println("  - IP: " + WiFi.localIP().toString());
  Serial.println("  - Señal: " + String(WiFi.RSSI()) + " dBm");
}

void scanI2C() {
  Serial.println("\n✓ Escaneando buses I2C...");
  byte error, address;
  int devices = 0;
  
  for (address = 1; address < 127; address++) {
    I2C_MLX.beginTransmission(address);
    error = I2C_MLX.endTransmission();
    if (error == 0) {
      Serial.print("  - Bus #1: 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      if (address == 0x5A) Serial.print(" (MLX90614)");
      Serial.println();
      devices++;
    }
    
    I2C_BH1750.beginTransmission(address);
    error = I2C_BH1750.endTransmission();
    if (error == 0) {
      Serial.print("  - Bus #2: 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      if (address == 0x23) Serial.print(" (BH1750)");
      Serial.println();
      devices++;
    }
  }
  
  Serial.println("  Total: " + String(devices) + " dispositivo(s)");
}

// ==================== MANEJO DE COMANDOS ====================
void handleCommand(WiFiClient& client, String command) {
  // ===== COMANDOS GASOX =====
  if (command.startsWith("SET_THRESHOLD_MQ4:")) {
    int newThreshold = command.substring(18).toInt();
    if (newThreshold >= 0 && newThreshold <= 80000) {
      mq4Threshold = newThreshold;
      saveThresholds();
      client.println("{\"status\":\"ok\",\"mq4_threshold\":" + String(mq4Threshold) + "}");
    } else {
      client.println("{\"status\":\"error\",\"message\":\"invalid_threshold\"}");
    }
  }
  else if (command.startsWith("SET_THRESHOLD_MQ7:")) {
    int newThreshold = command.substring(18).toInt();
    if (newThreshold >= 0 && newThreshold <= 80000) {
      mq7Threshold = newThreshold;
      saveThresholds();
      client.println("{\"status\":\"ok\",\"mq7_threshold\":" + String(mq7Threshold) + "}");
    } else {
      client.println("{\"status\":\"error\",\"message\":\"invalid_threshold\"}");
    }
  }
  else if (command == "GET_VALUES") {
    int mq4 = analogRead(MQ4_PIN);
    int mq7 = analogRead(MQ7_PIN);
    String response = "{\"mq4\":" + String(mq4) + 
                     ",\"mq7\":" + String(mq7) + 
                     ",\"alarm\":" + String(alarmState) + 
                     ",\"mq4_threshold\":" + String(mq4Threshold) + 
                     ",\"mq7_threshold\":" + String(mq7Threshold) + "}";
    client.println(response);
  }
  else if (command == "GET_THRESHOLDS") {
    String response = "{\"mq4_threshold\":" + String(mq4Threshold) + 
                     ",\"mq7_threshold\":" + String(mq7Threshold) + "}";
    client.println(response);
  }
  else if (command == "GET_ALARM_STATE") {
    String alarmResponse = alarmState ? "ALARMA_ACTIVA" : "SIN_ALARMA";
    client.println(alarmResponse);
  }
  
  // ===== COMANDOS FERSXMET =====
  else if (command == "GET_WEATHER") {
    sendWeatherData(client);
  }
  else if (command == "GET_THERMAL") {
    sendThermalData(client);
  }
  else if (command == "GET_STATUS") {
    sendStatus(client);
  }
  
  // ===== COMANDOS COMPARTIDOS =====
  else if (command == "GET_IP") {
    client.println(WiFi.localIP());
  }
  else if (command == "FORGET_WIFI") {
    client.println("OLVIDANDO_WIFI");
    client.flush();
    delay(100);
    WiFi.disconnect(true, true);
    ESP.restart();
  }
  else {
    client.println("COMANDO_DESCONOCIDO");
  }
}

// ==================== FUNCIONES GASOX ====================
void saveThresholds() {
  preferences.begin("gasox", false);
  preferences.putInt("mq4_thresh", mq4Threshold);
  preferences.putInt("mq7_thresh", mq7Threshold);
  preferences.end();
}


// ==================== FUNCIONES FERSXMET ====================
void sendWeatherData(WiFiClient &client) {
  float temp = 0.0, hum = 0.0, lux = 0.0;
  
  if (dhtAvailable) {
    temp = dht.readTemperature();
    hum = dht.readHumidity();
    if (isnan(temp)) temp = 0.0;
    if (isnan(hum)) hum = 0.0;
  }
  
  if (bh1750Available) {
    lux = lightMeter.readLightLevel();
    if (isnan(lux) || lux < 0) lux = 0.0;
  }
  
  StaticJsonDocument<200> doc;
  doc["temperature"] = round(temp * 10) / 10.0;
  doc["humidity"] = round(hum * 10) / 10.0;
  doc["luminosity"] = round(lux * 10) / 10.0;
  
  String response;
  serializeJson(doc, response);
  client.println(response);
}

void sendThermalData(WiFiClient &client) {
  if (!mlxAvailable) {
    client.println("{\"error\":\"MLX90614 no disponible\"}");
    return;
  }
  
  float ambientTemp = mlx.readAmbientTempC();
  float objectTemp = mlx.readObjectTempC();
  
  if (isnan(ambientTemp)) ambientTemp = 0.0;
  if (isnan(objectTemp)) objectTemp = 0.0;
  
  StaticJsonDocument<200> doc;
  doc["ambient_temp"] = round(ambientTemp * 10) / 10.0;
  doc["object_temp"] = round(objectTemp * 10) / 10.0;
  doc["difference"] = round((objectTemp - ambientTemp) * 10) / 10.0;
  
  String response;
  serializeJson(doc, response);
  client.println(response);
}

void sendStatus(WiFiClient &client) {
  StaticJsonDocument<400> doc;
  
  doc["wifi_ssid"] = WiFi.SSID();
  doc["wifi_rssi"] = WiFi.RSSI();
  doc["ip"] = WiFi.localIP().toString();
  doc["uptime"] = millis() / 1000;
  doc["free_heap"] = ESP.getFreeHeap();
  
  JsonObject sensors = doc.createNestedObject("sensors");
  sensors["mlx90614"] = mlxAvailable;
  sensors["dht22"] = dhtAvailable;
  sensors["bh1750"] = bh1750Available;
  sensors["mq4"] = true;
  sensors["mq7"] = true;
  
  String response;
  serializeJson(doc, response);
  client.println(response);
}

// ==================== FUNCIONES DE MONITOREO ====================
void printAllReadings(int mq4, int mq7) {
  Serial.println("\n╔════════════════════════════════════════════╗");
  Serial.println("║        LECTURAS DEL SISTEMA UNIFICADO      ║");
  Serial.println("╚════════════════════════════════════════════╝");
  
  // GASOX
  Serial.println("\n🔥 GASOX - Sensores de Gas:");
  Serial.println("   • MQ4 (Metano): " + String(mq4) + " / " + String(mq4Threshold));
  Serial.println("   • MQ7 (CO): " + String(mq7) + " / " + String(mq7Threshold));
  Serial.println("   • Alarma: " + String(alarmState ? "ACTIVA ⚠️" : "Inactiva ✓"));
  
  // FERSXMET - DHT22
  if (dhtAvailable) {
    Serial.println("\n🌡️  FERSXMET - DHT22:");
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    if (!isnan(temp) && !isnan(hum)) {
      Serial.println("   • Temperatura: " + String(temp, 1) + " °C");
      Serial.println("   • Humedad: " + String(hum, 1) + " %");
    }
  }
  
  // FERSXMET - BH1750
  if (bh1750Available) {
    Serial.println("\n💡 FERSXMET - BH1750:");
    float lux = lightMeter.readLightLevel();
    if (!isnan(lux) && lux >= 0) {
      Serial.println("   • Luminosidad: " + String(lux, 1) + " lux");
    }
  }
  
  // FERSXMET - MLX90614
  if (mlxAvailable) {
    Serial.println("\n🌡️  FERSXMET - MLX90614:");
    float ambientTemp = mlx.readAmbientTempC();
    float objectTemp = mlx.readObjectTempC();
    if (!isnan(ambientTemp) && !isnan(objectTemp)) {
      Serial.println("   • Temp ambiente: " + String(ambientTemp, 1) + " °C");
      Serial.println("   • Temp objeto: " + String(objectTemp, 1) + " °C");
    }
  }
  
  Serial.println("\n════════════════════════════════════════════\n");
}

/*
 * FERSXMET - Sistema Meteorológico
 * 
 * Sensores: BH1750 (Luz), MLX90614 (Temp IR), DHT22 (Temp/Humedad)
 * REST API en puerto 8080
 */

#include <WiFi.h>
#include <WiFiManager.h>
#include <ESPmDNS.h>
#include <Wire.h>
#include <Adafruit_MLX90614.h>
#include <DHT.h>
#include <BH1750.h>
#include <ArduinoJson.h>

// ==================== CONFIGURACIÓN ====================
#define DHT_PIN 4
#define DHT_TYPE DHT22
#define I2C1_SDA 16
#define I2C1_SCL 17
#define I2C2_SDA 21
#define I2C2_SCL 22

#define SERVER_PORT 8080
#define WIFI_SSID "FERSXMET_ESP32"

// ==================== OBJETOS GLOBALES ====================
WiFiServer server(SERVER_PORT);

TwoWire I2C_MLX = TwoWire(0);
TwoWire I2C_BH1750 = TwoWire(1);
Adafruit_MLX90614 mlx = Adafruit_MLX90614();
DHT dht(DHT_PIN, DHT_TYPE);
BH1750 lightMeter;

// ==================== VARIABLES DE ESTADO ====================
bool mlxAvailable = false;
bool dhtAvailable = false;
bool bh1750Available = false;

unsigned long lastReadingTime = 0;
const unsigned long READING_INTERVAL = 5000;

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n╔════════════════════════════════════════════╗");
  Serial.println("║       FERSXMET - Sistema Meteorológico     ║");
  Serial.println("╚════════════════════════════════════════════╝\n");
  
  // Inicializar buses I2C
  Serial.println("✓ Inicializando buses I2C...");
  I2C_MLX.begin(I2C1_SDA, I2C1_SCL, 100000);
  I2C_BH1750.begin(I2C2_SDA, I2C2_SCL, 400000);
  Serial.println("  - Bus I2C #1 (MLX90614): SDA=" + String(I2C1_SDA) + ", SCL=" + String(I2C1_SCL));
  Serial.println("  - Bus I2C #2 (BH1750):   SDA=" + String(I2C2_SDA) + ", SCL=" + String(I2C2_SCL));
  
  // Escanear y inicializar sensores
  scanI2C();
  initSensors();
  
  // Configurar WiFi
  setupWiFi();
  
  // Iniciar mDNS
  if (MDNS.begin("fersxmet")) {
    MDNS.addService("http", "tcp", SERVER_PORT);
    Serial.println("✓ mDNS iniciado: fersxmet.local");
  }
  
  // Iniciar servidor
  server.begin();
  Serial.println("\n✓ Servidor iniciado en puerto " + String(SERVER_PORT));
  Serial.println("✓ Sistema listo - Esperando conexiones...\n");
}

// ==================== LOOP PRINCIPAL ====================
void loop() {
  // Mostrar lecturas periódicas
  if (millis() - lastReadingTime >= READING_INTERVAL) {
    lastReadingTime = millis();
    printReadings();
  }
  
  // Manejar clientes
  WiFiClient client = server.available();
  if (client) {
    handleClient(client);
  }
  
  delay(100);
}

// ==================== FUNCIONES DE INICIALIZACIÓN ====================
void setupWiFi() {
  Serial.println("\n✓ Configurando WiFi...");
  
  WiFiManager wm;
  wm.setConfigPortalTimeout(180);
  
  wm.setCustomHeadElement(
    "<style>"
    "body{background-color:#222;}"
    "h1,h2,h3,label,legend,span,div,td,th,p,a{color:#00BFFF!important;}"
    "button,input[type='submit'],.btn{background-color:#00BFFF!important;color:#222!important;font-weight:bold;}"
    "input,select{background-color:#333!important;color:#00BFFF!important;border:1px solid #00BFFF!important;}"
    "</style>"
  );
  
  if (!wm.autoConnect(WIFI_SSID)) {
    Serial.println("Error de conexión, reiniciando...");
    delay(3000);
    ESP.restart();
  }
  
  Serial.println("✓ WiFi conectado!");
  Serial.println("  - SSID: " + WiFi.SSID());
  Serial.println("  - IP: " + WiFi.localIP().toString());
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

void initSensors() {
  Serial.println("\n✓ Inicializando sensores...");
  
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

// ==================== MANEJO DE CLIENTES ====================
void handleClient(WiFiClient& client) {
  Serial.println("\n>>> Cliente conectado <<<");
  
  while (client.connected()) {
    if (client.available()) {
      String command = client.readStringUntil('\n');
      command.trim();
      
      if (command.length() > 0) {
        Serial.println("Comando: " + command);
        processCommand(client, command);
        client.flush();
        break;
      }
    }
  }
  
  delay(10);
  client.stop();
  Serial.println(">>> Cliente desconectado <<<\n");
}

void processCommand(WiFiClient& client, String command) {
  if (command == "GET_WEATHER") {
    sendWeatherData(client);
  }
  else if (command == "GET_THERMAL") {
    sendThermalData(client);
  }
  else if (command == "GET_ALL") {
    sendAllData(client);
  }
  else if (command == "GET_STATUS") {
    sendStatus(client);
  }
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
    client.println("{\"error\":\"COMANDO_DESCONOCIDO\"}");
  }
}

// ==================== FUNCIONES DE DATOS ====================
void sendWeatherData(WiFiClient &client) {
  StaticJsonDocument<256> doc;
  
  if (dhtAvailable) {
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    doc["temperature"] = isnan(temp) ? 0.0 : round(temp * 10) / 10.0;
    doc["humidity"] = isnan(hum) ? 0.0 : round(hum * 10) / 10.0;
  } else {
    doc["temperature"] = 0.0;
    doc["humidity"] = 0.0;
  }
  
  if (bh1750Available) {
    float lux = lightMeter.readLightLevel();
    doc["luminosity"] = (isnan(lux) || lux < 0) ? 0.0 : round(lux * 10) / 10.0;
  } else {
    doc["luminosity"] = 0.0;
  }
  
  String response;
  serializeJson(doc, response);
  client.println(response);
}

void sendThermalData(WiFiClient &client) {
  StaticJsonDocument<256> doc;
  
  if (!mlxAvailable) {
    doc["error"] = "MLX90614 no disponible";
  } else {
    float ambientTemp = mlx.readAmbientTempC();
    float objectTemp = mlx.readObjectTempC();
    
    doc["ambient_temp"] = isnan(ambientTemp) ? 0.0 : round(ambientTemp * 10) / 10.0;
    doc["object_temp"] = isnan(objectTemp) ? 0.0 : round(objectTemp * 10) / 10.0;
    doc["difference"] = round((objectTemp - ambientTemp) * 10) / 10.0;
  }
  
  String response;
  serializeJson(doc, response);
  client.println(response);
}

void sendAllData(WiFiClient &client) {
  StaticJsonDocument<512> doc;
  
  // DHT22
  JsonObject weather = doc.createNestedObject("weather");
  if (dhtAvailable) {
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    weather["temperature"] = isnan(temp) ? 0.0 : round(temp * 10) / 10.0;
    weather["humidity"] = isnan(hum) ? 0.0 : round(hum * 10) / 10.0;
  }
  
  // BH1750
  if (bh1750Available) {
    float lux = lightMeter.readLightLevel();
    weather["luminosity"] = (isnan(lux) || lux < 0) ? 0.0 : round(lux * 10) / 10.0;
  }
  
  // MLX90614
  JsonObject thermal = doc.createNestedObject("thermal");
  if (mlxAvailable) {
    float ambientTemp = mlx.readAmbientTempC();
    float objectTemp = mlx.readObjectTempC();
    thermal["ambient_temp"] = isnan(ambientTemp) ? 0.0 : round(ambientTemp * 10) / 10.0;
    thermal["object_temp"] = isnan(objectTemp) ? 0.0 : round(objectTemp * 10) / 10.0;
  }
  
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
  
  String response;
  serializeJson(doc, response);
  client.println(response);
}

void printReadings() {
  Serial.println("\n╔════════════════════════════════════════════╗");
  Serial.println("║         FERSXMET - Lecturas                ║");
  Serial.println("╚════════════════════════════════════════════╝");
  
  if (dhtAvailable) {
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    Serial.println("\n🌡️  DHT22:");
    if (!isnan(temp) && !isnan(hum)) {
      Serial.println("   • Temperatura: " + String(temp, 1) + " °C");
      Serial.println("   • Humedad: " + String(hum, 1) + " %");
    }
  }
  
  if (bh1750Available) {
    float lux = lightMeter.readLightLevel();
    Serial.println("\n💡 BH1750:");
    if (!isnan(lux) && lux >= 0) {
      Serial.println("   • Luminosidad: " + String(lux, 1) + " lux");
    }
  }
  
  if (mlxAvailable) {
    float ambientTemp = mlx.readAmbientTempC();
    float objectTemp = mlx.readObjectTempC();
    Serial.println("\n🔥 MLX90614:");
    if (!isnan(ambientTemp) && !isnan(objectTemp)) {
      Serial.println("   • Temp ambiente: " + String(ambientTemp, 1) + " °C");
      Serial.println("   • Temp objeto: " + String(objectTemp, 1) + " °C");
    }
  }
  
  Serial.println("\n════════════════════════════════════════════\n");
}

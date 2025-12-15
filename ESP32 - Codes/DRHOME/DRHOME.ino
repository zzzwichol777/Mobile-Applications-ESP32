/*
 * DrHome - Sistema Médico ESP32
 * PROTOCOLO IDÉNTICO A GASOX Y FERSXMET
 */

#include <WiFiManager.h>
#include <ESPmDNS.h>
#include <Wire.h>
#include <Adafruit_MLX90614.h>
#include <MAX30105.h>
#include <heartRate.h>

WiFiServer server(8080);

// Pines I2C
#define I2C1_SDA 16
#define I2C1_SCL 17
#define I2C2_SDA 21
#define I2C2_SCL 22

// Objetos
TwoWire I2C_MAX = TwoWire(0);
TwoWire I2C_MLX = TwoWire(1);
MAX30105 particleSensor;
Adafruit_MLX90614 mlx = Adafruit_MLX90614();

// Variables de estado
bool max30102Available = false;
bool mlx90614Available = false;
float currentHeartRate = 0;
float currentSpO2 = 0;
float currentBodyTemp = 0;

// Variables para detección de latidos
const byte RATE_SIZE = 4;
byte rates[RATE_SIZE];
byte rateSpot = 0;
long lastBeat = 0;

void setup() {
    Serial.begin(115200);
    
    // Inicializar I2C
    I2C_MAX.begin(I2C1_SDA, I2C1_SCL, 400000);
    I2C_MLX.begin(I2C2_SDA, I2C2_SCL, 100000);
    
    // Inicializar sensores
    if (particleSensor.begin(I2C_MAX, I2C_SPEED_STANDARD)) {
        particleSensor.setup();
        particleSensor.setPulseAmplitudeRed(0x0A);
        particleSensor.setPulseAmplitudeIR(0x0A);
        max30102Available = true;
    }
    
    if (mlx.begin(0x5A, &I2C_MLX)) {
        mlx90614Available = true;
    }
    
    // Configurar WiFi (IGUAL QUE GASOX)
    WiFiManager wm;
    wm.setCustomHeadElement(
        "<style>"
        "body{background-color:#f0f4f8;}"
        "h1,h2,h3{color:#2563eb!important;}"
        "label,legend,span,div,td,th,p,a{color:#1e40af!important;}"
        "button,input[type='submit'],.btn{background-color:#3b82f6!important;color:#fff!important;font-weight:bold;border-radius:8px;}"
        "input,select{background-color:#fff!important;color:#1e40af!important;border:2px solid #93c5fd!important;border-radius:6px;}"
        ".msg{color:#2563eb!important;}"
        "</style>"
    );
    
    wm.setAPCallback([](WiFiManager* wm) {
        Serial.println("Conéctate a la red DrHome y abre el portal para configurar.");
    });
    
    wm.setSaveConfigCallback([]() {
        Serial.println("Configuración guardada, reiniciando...");
    });
    
    wm.autoConnect("DrHome");
    
    Serial.println("WiFi conectado!");
    Serial.print("Dirección IP: ");
    Serial.println(WiFi.localIP());
    
    if (!MDNS.begin("drhome")) {
        Serial.println("Error al iniciar mDNS");
        delay(1000);
        ESP.restart();
    }
    MDNS.addService("http", "tcp", 8080);
    
    Serial.println("Sistema iniciado correctamente");
    Serial.println("IP: " + WiFi.localIP().toString());
    
    server.begin();
    Serial.println("Servidor iniciado en puerto 8080");
}

void loop() {
    // Actualizar lecturas de sensores
    if (max30102Available) {
        long irValue = particleSensor.getIR();
        
        if (irValue > 50000) {
            if (checkForBeat(irValue)) {
                long delta = millis() - lastBeat;
                lastBeat = millis();
                float beatsPerMinute = 60 / (delta / 1000.0);
                
                if (beatsPerMinute < 255 && beatsPerMinute > 20) {
                    rates[rateSpot++] = (byte)beatsPerMinute;
                    rateSpot %= RATE_SIZE;
                    
                    int beatAvg = 0;
                    for (byte x = 0; x < RATE_SIZE; x++) {
                        beatAvg += rates[x];
                    }
                    beatAvg /= RATE_SIZE;
                    currentHeartRate = beatAvg;
                }
            }
            
            long redValue = particleSensor.getRed();
            if (redValue > 50000) {
                float ratio = (float)redValue / (float)irValue;
                currentSpO2 = 104 - 17 * ratio;
                if (currentSpO2 > 100) currentSpO2 = 100;
                if (currentSpO2 < 70) currentSpO2 = 70;
            }
        } else {
            currentHeartRate = 0;
            currentSpO2 = 0;
        }
    }
    
    if (mlx90614Available) {
        float temp = mlx.readObjectTempC();
        if (!isnan(temp) && temp >= 30.0 && temp <= 45.0) {
            currentBodyTemp = temp;
        }
    }
    
    // Manejar clientes (EXACTAMENTE COMO GASOX)
    WiFiClient client = server.available();
    if (client) {
        while (client.connected()) {
            if (client.available()) {
                String command = client.readStringUntil('\n');
                command.trim();
                
                // Debug
                Serial.println("Comando recibido: " + command);
                
                handleCommand(client, command);
                
                client.flush();
            }
        }
        client.stop();
    }
    
    delay(100);
}

void handleCommand(WiFiClient& client, String command) {
    if (command == "GET_VITALS") {
        // Formato JSON simple
        String response = "{\"heart_rate\":" + String((int)currentHeartRate) + 
                         ",\"spo2\":" + String((int)currentSpO2) + 
                         ",\"body_temp\":" + String(currentBodyTemp, 1) + 
                         ",\"finger_detected\":" + String(max30102Available && particleSensor.getIR() > 50000 ? "true" : "false") + 
                         ",\"measuring\":false}";
        client.println(response);
    }
    else if (command == "START_MEASUREMENT") {
        client.println("{\"status\":\"ok\",\"message\":\"Medición iniciada\"}");
    }
    else if (command == "STOP_MEASUREMENT") {
        client.println("{\"status\":\"ok\",\"message\":\"Medición detenida\"}");
    }
    else if (command == "GET_STATUS") {
        String response = "{\"wifi_ssid\":\"" + WiFi.SSID() + 
                         "\",\"wifi_rssi\":" + String(WiFi.RSSI()) + 
                         ",\"ip\":\"" + WiFi.localIP().toString() + 
                         "\",\"uptime\":" + String(millis() / 1000) + 
                         ",\"free_heap\":" + String(ESP.getFreeHeap()) + 
                         ",\"sensors\":{\"max30102\":" + String(max30102Available ? "true" : "false") + 
                         ",\"mlx90614\":" + String(mlx90614Available ? "true" : "false") + "}}";
        client.println(response);
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
        client.println("COMANDO_DESCONOCIDO");
        Serial.println("Comando desconocido: " + command);
    }
}

/*
 * GASOX - Detector de Gases
 * 
 * Sensores: MQ4 (Metano) y MQ7 (Monóxido de Carbono)
 * REST API en puerto 8080
 */

#include <WiFiManager.h>
#include <ESPmDNS.h>
#include <Preferences.h>

WiFiServer server(8080);
Preferences preferences;

// Configuración de pines
const int LED_PIN = 13;
const int BUZZER_PIN = 26;
const int MQ4_PIN = 34;
const int MQ7_PIN = 35;

// Variables de estado
int mq4Threshold = 3000;
int mq7Threshold = 3000;
bool alarmState = false;
bool ledState = false;
unsigned long lastBlinkTime = 0;
const unsigned long BLINK_INTERVAL = 500;

void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
    pinMode(BUZZER_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);
    digitalWrite(BUZZER_PIN, LOW);

    // Cargar umbrales guardados
    preferences.begin("gasox", true);
    mq4Threshold = preferences.getInt("mq4_thresh", 3000);
    mq7Threshold = preferences.getInt("mq7_thresh", 3000);
    preferences.end();

    WiFiManager wifiManager;

  // Cambia el color del portal a naranja
  wifiManager.setCustomHeadElement(
    "<style>"
    "body{background-color:#222;}"
    "h1,h2,h3,label,legend,span,div,td,th,p,a{color:#FFA500!important;}"
    "button,input[type='submit'],.btn{background-color:#FFA500!important;color:#222!important;font-weight:bold;}"
    "input,select{background-color:#333!important;color:#FFA500!important;border:1px solid #FFA500!important;}"
    ".msg{color:#FFA500!important;}"
    "</style>"
  );

  wifiManager.setAPCallback([](WiFiManager* wm) {
    Serial.println("Conéctate a la red GASOX y abre el portal para configurar.");
  });

  wifiManager.setSaveConfigCallback([]() {
    Serial.println("Configuración guardada, reiniciando...");
  });

  wifiManager.autoConnect("GASOX");

  // Mostrar la IP en el portal tras la conexión
  String ipMsg = "<div style='margin:24px 0;padding:16px;background:#222;border:2px solid #FFA500;border-radius:12px;'>";
  ipMsg += "<h2 style='color:#FFA500;'>¡Conexión exitosa!</h2>";
  ipMsg += "<p style='color:#FFA500;font-size:18px;'>La nueva IP de tu ESP32 es:</p>";
  ipMsg += "<div style='font-size:22px;font-weight:bold;color:#FFA500;background:#333;padding:8px 16px;border-radius:8px;display:inline-block;'>";
  ipMsg += WiFi.localIP().toString();
  ipMsg += "</div>";
  ipMsg += "<p style='color:#FFA500;'>Cópiala y pégala en la app si gasox.local no funciona.</p>";
  ipMsg += "</div>";

  wifiManager.setCustomMenuHTML(ipMsg.c_str());

  Serial.println("WiFi conectado!");
  Serial.print("Dirección IP: ");
  Serial.println(WiFi.localIP());
  
  if (!MDNS.begin("gasox")) {
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

void saveThresholds() {
    preferences.begin("gasox", false);
    preferences.putInt("mq4_thresh", mq4Threshold);
    preferences.putInt("mq7_thresh", mq7Threshold);
    preferences.end();
}

void activateAlarm(bool state) {
    unsigned long currentMillis = millis();
    
    if (state) {
        if (currentMillis - lastBlinkTime >= BLINK_INTERVAL) {
            ledState = !ledState;
            digitalWrite(LED_PIN, ledState);
            digitalWrite(BUZZER_PIN, ledState);
            lastBlinkTime = currentMillis;
        }
    } else {
        digitalWrite(LED_PIN, LOW);
        digitalWrite(BUZZER_PIN, LOW);
        ledState = false;
    }
}

void handleCommand(WiFiClient& client, String command) {
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
          Serial.println("Estado de alarma enviado: " + alarmResponse);
    } else if (command == "GET_IP") {
          client.println(WiFi.localIP());
    } else if (command == "FORGET_WIFI") {
          client.println("OLVIDANDO_WIFI");
          client.flush();
          delay(100);
          WiFi.disconnect(true, true);
          ESP.restart();
    } else {
          client.println("COMANDO_DESCONOCIDO");
          Serial.println("Comando desconocido: " + command);
    }
}

void loop() {
    int mq4Value = analogRead(MQ4_PIN);
    int mq7Value = analogRead(MQ7_PIN);

    // Verificar umbrales y activar alarma
    bool shouldAlarm = (mq4Value > mq4Threshold) || (mq7Value > mq7Threshold);
    
    if (shouldAlarm != alarmState) {
        alarmState = shouldAlarm;
    }
    
    activateAlarm(alarmState);

    // Manejar clientes
    WiFiClient client = server.available();
    if (client) {
      while (client.connected()) {
        if (client.available()) {
          String command = client.readStringUntil('\n');
          command.trim();
          
          // Debug
          Serial.println("Comando recibido: " + command);
          
          // Usar handleCommand para procesar todos los comandos
          handleCommand(client, command);
          
          client.flush();
        }
      }
      client.stop();
    }
    
    delay(100);
}
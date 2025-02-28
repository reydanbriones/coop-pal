#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>

const char* ssid = "WirelessNet";
const char* password = "mangkotasiadi";
const char* server = "http://192.168.100.10/coop_pal/get_actuator_states.php";

void setup() {
  Serial.begin(9600);
  WiFi.begin(ssid, password);

  // Wait for WiFi connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClient client;
    HTTPClient http;
    http.begin(client, server);
    int httpResponseCode = http.GET();

    if (httpResponseCode > 0) {
      String payload = http.getString();
      // Serial.println("Server response: " + payload);

      // Parse JSON response
      DynamicJsonDocument doc(1024);
      DeserializationError error = deserializeJson(doc, payload);

      if (!error) {
        int fan = doc["fan"];
        int ledBulb = doc["led_bulb"];

        // Send actuator states to Arduino Uno
        String dataToSend = String(fan) + "," + String(ledBulb) + "\n";
        Serial.print(dataToSend); // Send to Arduino Uno
      } else {
        Serial.println("Error parsing JSON");
      }
    } else {
      Serial.println("Error fetching data: " + String(httpResponseCode));
    }
    http.end();
  }

  delay(3000);
}
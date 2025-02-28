#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266HTTPClient.h>

const char* ssid = "WirelessNet";
const char* password = "mangkotasiadi";
const char* server = "http://192.168.100.10/coop_pal/set_sensor_data.php";

WiFiClient client;

void setup() {
  Serial.begin(9600);
  WiFi.begin(ssid, password);

  // Wait for WiFi connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected.");
}

void loop() {
  // Check if data is available from Arduino Uno
  if (Serial.available() > 0) {
    String data = Serial.readStringUntil('\n');
    data.trim();

    // Parse the received data
    int separator1 = data.indexOf(',');
    int separator2 = data.indexOf(',', separator1 + 1);
    int separator3 = data.indexOf(',', separator2 + 1);
    int separator4 = data.indexOf(',', separator3 + 1);
    int separator5 = data.indexOf(',', separator4 + 1);
    int separator6 = data.indexOf(',', separator5 + 1);
    int separator7 = data.indexOf(',', separator6 + 1);

    if (separator1 != -1 && separator4 != -1) {
      String ldrValue = data.substring(0, separator1);
      String temperature = data.substring(separator1 + 1, separator2);
      String humidity = data.substring(separator2 + 1, separator3);
      String mq9Value = data.substring(separator3 + 1, separator4);
      String mq135Value = data.substring(separator4 + 1, separator5);
      String distance = data.substring(separator5 + 1, separator6);
      String waterWeight = data.substring(separator6 + 1, separator7);
      String feedsWeight = data.substring(separator7 + 1);

      Serial.println("LDR Value: " + ldrValue);
      Serial.println("Temperature: " + temperature);
      Serial.println("Humidity: " + humidity);
      Serial.println("MQ9 Value: " + mq9Value);
      Serial.println("MQ135 Value: " + mq135Value);
      Serial.println("Ultrasonic Value: " + distance);
      Serial.println("Water Weight: " + waterWeight);
      Serial.println("Feeds Weight: " + feedsWeight);

      // Upload the data to the database
      HTTPClient http;
      http.begin(client, server);
      http.addHeader("Content-Type", "application/x-www-form-urlencoded");

      String postData = "ldr_value=" + ldrValue +
                        "&temperature=" + temperature +
                        "&humidity=" + humidity +
                        "&mq9=" + mq9Value +
                        "&mq135=" + mq135Value +
                        "&egg_range=" + distance +
                        "&water_weight=" + waterWeight +
                        "&feeds_weight=" + feedsWeight;

      int httpResponseCode = http.POST(postData);

      if (httpResponseCode > 0) {
        String payload = http.getString();
        Serial.println("Response: " + payload);
      } else {
        Serial.println("Error uploading data.");
      }
      http.end();
    } else {
      Serial.println("Error parsing data.");
    }
  }

  delay(500);
}
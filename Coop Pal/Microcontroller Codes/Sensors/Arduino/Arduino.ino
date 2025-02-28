#include <DHT.h>
#include "HX711.h"
#define DHTPIN 2
#define DHTTYPE DHT11  
#define LDRPIN A3    
#define MQ9PIN A4
#define MQ135PIN A5 
#define TRIGPIN 3
#define ECHOPIN 4
// Load cell 1 (Water container)
#define LOADCELL1_DOUT_PIN 5
#define LOADCELL1_SCK_PIN 6
// Load cell 2 (Feeds container)
#define LOADCELL2_DOUT_PIN 7
#define LOADCELL2_SCK_PIN 8

// For test purposes.
#define testPin 9

HX711 scale1;
HX711 scale2;
DHT dht(DHTPIN, DHTTYPE);

// Replace with final calibration factor
float calibration_factor1 = -7050;
float calibration_factor2 = -7050;

void setup() {
  Serial.begin(9600); 
  dht.begin();         
  pinMode(TRIGPIN, OUTPUT);
  pinMode(ECHOPIN, INPUT);
  scale1.begin(LOADCELL1_DOUT_PIN, LOADCELL1_SCK_PIN);
  scale1.set_scale(calibration_factor1);
  scale1.tare(); 
  scale2.begin(LOADCELL2_DOUT_PIN, LOADCELL2_SCK_PIN);
  scale2.set_scale(calibration_factor2);
  scale2.tare(); 

  // For test purposes.
  pinMode(testPin, OUTPUT); 
}

void loop() {
  // Processing for ultrasonic
  long duration = 0;
  int distance = 0;
  // Clear the trigger
  digitalWrite(TRIGPIN, LOW);
  delayMicroseconds(2);
  // Set the trigger HIGH for 10 microseconds
  digitalWrite(TRIGPIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIGPIN, LOW);
  // Read the echo
  duration = pulseIn(ECHOPIN, HIGH);
  // Calculate the distance (In centimeters)
  distance = duration * 0.034 / 2;

  // Processing for load cells
  float weight1 = 0;
  float weight2 = 0;
  if (scale1.is_ready() && scale2.is_ready()) {
    // Water container (In kilograms)
    weight1 = scale1.get_units(10); 
    // Feeds container (In kilograms)
    weight2 = scale2.get_units(10); 
  }

  int ldrValue = analogRead(LDRPIN);
  int mq9Value = analogRead(MQ9PIN);         
  int mq135Value = analogRead(MQ135PIN);     
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Error reading DHT11 sensor.");
  } else {
    // Send readings to NodeMCU in a single line
    Serial.print(ldrValue);
    Serial.print(",");
    Serial.print(temperature);
    Serial.print(",");
    Serial.print(humidity);
    Serial.print(",");
    Serial.print(mq9Value);
    Serial.print(",");
    Serial.print(mq135Value);
    Serial.print(",");
    Serial.print(distance);
    Serial.print(",");
    Serial.print(weight1);
    Serial.print(",");
    Serial.println(weight2);
    
    // For test purposes.
    digitalWrite(testPin, HIGH);
    delay(1000);
    digitalWrite(testPin, LOW);
    delay(1000);
  }

  // Adjust interval for sensor scan
  delay(3000);
}
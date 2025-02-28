#define fan       2
#define ledBulb   3

void setup() {
  Serial.begin(9600);

  pinMode(fan, OUTPUT);
  pinMode(ledBulb, OUTPUT);

  digitalWrite(fan, LOW);
  digitalWrite(ledBulb, LOW);
}

void loop() {
  if (Serial.available() > 0) {
    String data = Serial.readStringUntil('\n');
    data.trim();

    int separator1 = data.indexOf(',');

    if (separator1 != -1) {
      int fanState = data.substring(0, separator1).toInt();
      int ledBulbState = data.substring(separator1 + 1).toInt();

      if (fanState == 0 || fanState == 1) {
        digitalWrite(fan, fanState);

        // For test purposes.
        Serial.print("Fan: ");
        Serial.print(fanState);
        Serial.print(" | ");

      }
      if (ledBulbState == 0 || ledBulbState == 1) {
        digitalWrite(ledBulb, ledBulbState);
        
        // For test purposes.
        Serial.print("Bulb: ");
        Serial.println(ledBulbState);
      }
    }
  }
  else {
    Serial.println("No data received.");
  }

  delay(500);
}
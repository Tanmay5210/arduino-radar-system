#include <SR04.h>
#include <Servo.h>

Servo myServo;

const int trig_pin = 11;
const int echo_pin = 10;

const int servoMax = 180;
const int servoMin = 0;

int pos = 0;
long distance;

SR04 sensor = SR04(echo_pin, trig_pin);

void setup()
{
  Serial.begin(9600);
  myServo.attach(12);
}

void loop()
{
  // Sweep from 0° to 180°
  for (pos = servoMin; pos <= servoMax; pos++)
  {
    myServo.write(pos);
    delay(15);

    distance = sensor.Distance();

    Serial.print(pos);
    Serial.print(",");
    Serial.print(distance);
    Serial.print(".");
  }

  // Sweep from 180° back to 0°
  for (pos = servoMax; pos >= servoMin; pos--)
  {
    myServo.write(pos);
    delay(15);

    distance = sensor.Distance();

    Serial.print(pos);
    Serial.print(",");
    Serial.print(distance);
    Serial.print(".");
  }
}

import processing.serial.*;

Serial myPort;

int realAngle = 0;
int realDistance = 0;

int previousAngle = 0;
int sweepDirection = 1;

float smoothDistance = 0;

float centreX;
float centreY;


void setup()
{
  size(1200, 700);

  centreX = width / 2;
  centreY = height - 50;

  // Change COM6 if your Arduino uses another port
  printArray(Serial.list());

  myPort = new Serial(this, "COM6", 9600);
  myPort.bufferUntil('.');
}


void draw()
{
  background(0);

  drawRadar();
  drawLabels();
  drawSweep();
  drawObject();
  drawHUD();
}


// ==================================================
// RADAR
// ==================================================

void drawRadar()
{
  noFill();

  stroke(0, 255, 0);
  strokeWeight(2);

  arc(centreX, centreY, 1000, 1000, PI, TWO_PI);
  arc(centreX, centreY, 750, 750, PI, TWO_PI);
  arc(centreX, centreY, 500, 500, PI, TWO_PI);
  arc(centreX, centreY, 250, 250, PI, TWO_PI);

  // Horizontal baseline
  line(centreX - 500, centreY,
       centreX + 500, centreY);

  // Radial angle lines
  stroke(0, 150, 0);
  strokeWeight(1);

  for (int angle = 30; angle < 180; angle += 30)
  {
    float x = centreX + 500 * cos(radians(angle));
    float y = centreY - 500 * sin(radians(angle));

    line(centreX, centreY, x, y);
  }

  stroke(0, 255, 0);
  strokeWeight(8);
  point(centreX, centreY);
}


// ==================================================
// SWEEP
// ==================================================

void drawSweep()
{
  if (realAngle > previousAngle)
  {
    sweepDirection = 1;
  }
  else if (realAngle < previousAngle)
  {
    sweepDirection = -1;
  }

  previousAngle = realAngle;

  // Fading trail
  for (int i = 1; i <= 12; i++)
  {
    float trailAngle;

    if (sweepDirection == 1)
    {
      trailAngle = realAngle - i * 2;
    }
    else
    {
      trailAngle = realAngle + i * 2;
    }

    if (trailAngle >= 0 && trailAngle <= 180)
    {
      float x = centreX + 500 * cos(radians(trailAngle));
      float y = centreY - 500 * sin(radians(trailAngle));

      stroke(0, 140 - i * 9, 0);
      strokeWeight(2);
      line(centreX, centreY, x, y);
    }
  }

  float sweepX = centreX + 500 * cos(radians(realAngle));
  float sweepY = centreY - 500 * sin(radians(realAngle));

  stroke(50, 255, 80);
  strokeWeight(5);
  line(centreX, centreY, sweepX, sweepY);

  stroke(150, 255, 150);
  strokeWeight(10);
  point(sweepX, sweepY);
}


// ==================================================
// OBJECT DETECTION
// ==================================================

void drawObject()
{
  if (realDistance > 0 && realDistance <= 40)
  {
    if (smoothDistance == 0)
    {
      smoothDistance = realDistance;
    }
    else
    {
      smoothDistance =
        smoothDistance * 0.85 + realDistance * 0.15;
    }

    float pixelDistance = smoothDistance * 12.5;

    float objectX =
      centreX + pixelDistance * cos(radians(realAngle));

    float objectY =
      centreY - pixelDistance * sin(radians(realAngle));

    // Outer glow
    noFill();
    stroke(255, 0, 0, 30);
    strokeWeight(18);
    ellipse(objectX, objectY, 35, 35);

    // Inner glow
    stroke(255, 30, 30, 100);
    strokeWeight(10);
    ellipse(objectX, objectY, 20, 20);

    // Contact point
    stroke(255, 80, 80);
    strokeWeight(6);
    point(objectX, objectY);
  }
  else
  {
    smoothDistance *= 0.9;
  }
}


// ==================================================
// LABELS
// ==================================================

void drawLabels()
{
  fill(0, 255, 0);
  textSize(18);

  text("10 cm", centreX + 115, centreY - 8);
  text("20 cm", centreX + 240, centreY - 8);
  text("30 cm", centreX + 365, centreY - 8);
  text("40 cm", centreX + 490, centreY - 8);

  text("0°",   centreX + 505, centreY + 25);
  text("30°",  centreX + 430, centreY - 245);
  text("60°",  centreX + 255, centreY - 435);
  text("90°",  centreX - 15,  centreY - 510);
  text("120°", centreX - 300, centreY - 435);
  text("150°", centreX - 475, centreY - 245);
  text("180°", centreX - 545, centreY + 25);
}


// ==================================================
// HUD
// ==================================================

void drawHUD()
{
  noStroke();
  fill(0, 40);
  rect(0, height - 45, width, 45);

  fill(0, 255, 0);
  textSize(20);

  text("ANGLE: " + realAngle + "°", 30, height - 15);
  text("DISTANCE: " + realDistance + " cm", 220, height - 15);

  if (realDistance > 0 && realDistance <= 40)
  {
    fill(255, 50, 50);
    text("CONTACT", 450, height - 15);
  }
  else
  {
    fill(0, 255, 0);
    text("SCANNING", 450, height - 15);
  }

  fill(0, 255, 0);
  textSize(28);
  text("TACTICAL RADAR", 30, 40);
}


// ==================================================
// SERIAL INPUT
// ==================================================

void serialEvent(Serial port)
{
  String data = port.readStringUntil('.');

  if (data == null)
  {
    return;
  }

  // Remove terminating period
  data = trim(data.substring(0, data.length() - 1));

  int comma = data.indexOf(',');

  if (comma == -1)
  {
    return;
  }

  try
  {
    int angle = Integer.parseInt(data.substring(0, comma).trim());
    long distance = Long.parseLong(data.substring(comma + 1).trim());

    // Accept only valid values
    if (angle >= 0 && angle <= 180 && distance >= 0)
    {
      realAngle = angle;
      realDistance = (int) min(distance, 32767);
    }
  }
  catch (NumberFormatException e)
  {
    // Ignore malformed serial packets
  }
}

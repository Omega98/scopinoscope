/*
 * Oscilloscope
 * Gives a visual rendering of analog pin 0 in realtime.
 * 
 * This project is part of Accrochages
 * See http://accrochages.drone.ws
 * 
 * (c) 2008 Sofian Audry (info@sofianaudry.com)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */ 
import processing.serial.*;

boolean simulation = true;
boolean jitter = false;

Serial port;  // Create object from Serial class

int graWidth;
int graHeight;
int graOriginX;
int graOriginY;
float zoom;

int n; 
int[] samples;

int smallTimeDivision;
int timeDivision;      // time division on x-axis, defined in nb of samples

int smallVoltDivision;
int voltDivision;      // volt division on y-axis, defined in volt scaled to byte (0-255)

float voltageOffset = 2.5;
boolean sampling;
int waitduration;
int threshold;
int prescaler;
 
PFont font;

Button startButton;
Button stopButton;
 
void setup() 
{
  // Open the port that the board is connected to and use the same speed (9600 bps)
  port = new Serial(this, Serial.list()[0], 115200);
  port.write("x");

  n = 1280;
  samples = new int[n];

  int graTopSpacing = 16;
  int graBottomSpacing = 64;
  int graLeftSpacing = 16;
  int graRightSpacing = 240;
  
  graWidth = n;
  graHeight = 480;
  graOriginX = graLeftSpacing;
  graOriginY = graTopSpacing;

  zoom = 1.0f;
  
  size(graLeftSpacing + graWidth + graRightSpacing, 
       graTopSpacing + graHeight + graBottomSpacing);
  smooth();

  smallTimeDivision = 16;
  timeDivision = 5*smallTimeDivision;

  smallVoltDivision = 16;
  voltDivision = 5*smallVoltDivision;

  sampling = false;
  waitduration = n - 640;
  threshold = 10;
  prescaler = 128;

  port.write("p" + Integer.toString(prescaler));
  port.write("w" + Integer.toString(n - waitduration));
  port.write("t" + Integer.toString(threshold));
  
  // The font must be located in the sketch's 
  // "data" directory to load successfully
  font = loadFont("Monospaced.bold-16.vlw");
  textFont(font, 16);
  
  startButton = new Button("START", graOriginX+graWidth-1+32, graOriginY+8+96+16, 64, 64, CENTER);
  stopButton = new Button("STOP", graOriginX+graWidth-1+32+64+8, graOriginY+8+96+16, 64, 64, CENTER);
}
 
int getY(int val) {
  return (int)(graHeight - val / 255.0f * (graHeight - 1));
}
 
void getBuffer() {
  if (simulation)
  {
    float f;
    float a;
    f = 1/0.133*2;
    a = 2.25;
    if (jitter)
    {
      f = random(f*0.95, f*1.05);
      a = random(a-0.03, a+0.03);
    }
    for (int i=0; i<n; i++)
    {
      float x = (i-(n - waitduration)) * getSecondPerDivision(prescaler) / timeDivision;
      pushValue(int( ((a*sin(TWO_PI*x/(1/f)))+2.50)/5.0*256.0 ));
    }
  }
  else
  {
    int bytesRead = 0;
    while (port.available() >= n) {
      if (port.read() == 0xff) {
        /* value = (port.read() << 8) | (port.read()); */
        for (int i=0; i<n; i++)
        {
          pushValue(port.read());
          bytesRead++;
        }
        if (bytesRead == n)
          break;
      }
    }
  }
}
 
void pushValue(int value) {
  for (int i=0; i<n-1; i++)
    samples[i] = samples[i+1];
  samples[n-1] = value;
}
 
void drawSignal() {
  stroke(162,227,227,192.0); // greenish blue, 75% opaque
  strokeWeight(4);
  strokeJoin(ROUND);
  
  int displayWidth = (int) (graWidth / zoom);
  
  int k = int(samples.length - n/zoom);
  
  int x0 = graOriginX;
  int y0 = graOriginY + getY(samples[k]);
  for (int i=1; i<displayWidth; i++) {
    k++;
    int x1 = graOriginX + (int) (i * (graWidth-1) / (displayWidth-1));
    int y1 = graOriginY + getY(samples[k]);
    line(x0, y0, x1, y1);
    x0 = x1;
    y0 = y1;
  }
}
 
void drawGrid() {
  stroke(97, 195, 97, 255.0); // green
  strokeWeight(2);
  strokeJoin(MITER);
  
  int dotStyle=4;
  
  // X-Axis
  dottedLine(graOriginX, graOriginY+graHeight/2, graOriginX+graWidth-1, graOriginY+graHeight/2, dotStyle*zoom);

  // Y-Axis
  int offset = n - waitduration;
  dottedLine(graOriginX+offset, graOriginY, graOriginX+offset, graOriginY+graHeight-1, dotStyle);
  
  // Small crossbars on x-axis
  for (int x=graOriginX+offset; x>graOriginX; x-=smallTimeDivision*zoom)
  {
    line(x, graOriginY+graHeight/2-2, x, graOriginY+graHeight/2+2);
  }
  for (int x=graOriginX+offset; x<graOriginX+graWidth-1; x+=smallTimeDivision*zoom)
  {
    line(x, graOriginY+graHeight/2-2, x, graOriginY+graHeight/2+2);
  }

  // Small crossbars on y-axis
  for (int y=graOriginY; y<graOriginY+graHeight-1; y+=smallVoltDivision)
  {
    line(graOriginX+offset-2, y, graOriginX+offset+2, y);
  }

  // Division bars crossing x-axis i.e. |||
  for (int x=graOriginX+offset; x>graOriginX; x-=timeDivision*zoom)
  {
    dottedLine(x, graOriginY, x, graOriginY+graHeight-1, 16);
  }
  for (int x=graOriginX+offset; x<graOriginX+graWidth-1; x+=timeDivision*zoom)
  {
    dottedLine(x, graOriginY, x, graOriginY+graHeight-1, 16);
  }
  
  // Division bars crossing y-axis i.e. = =
  for (int y=graOriginY; y<graOriginY+graHeight-1; y+=voltDivision)
  {
    dottedLine(graOriginX+offset, y, graOriginX, y, smallTimeDivision*zoom);
    dottedLine(graOriginX+offset, y, graOriginX+graWidth-1, y, smallTimeDivision*zoom);
  }
  
  // Frame
  strokeWeight(4);
  noFill();
  rect(graOriginX-1, graOriginY-1, graWidth+1, graHeight+1); 
}

void drawTexts()
{
  fill(97, 195, 97, 255.0); // green
  float sps = getSecondPerSample(prescaler);

  // full left x value (x0)
  textAlign(LEFT);
  float x0 = (n - waitduration) * sps * 1000.0;
  String unit = "ms";
  if (x0 < 0.001)
  {
    x0 *= 1000.0;
    unit = "us";
  }
  String x0Text = String.format("%.3f %s", -x0, unit);
  text(x0Text, graOriginX+4, graOriginY+graHeight+16);  

  // full right x value
  textAlign(RIGHT);
  float endset = waitduration * sps * 1000.0;
  unit = "ms";
  if (endset < 0.001)
  {
    endset *= 1000.0;
    unit = "us";
  }
  String endsetText = String.format("%.3f %s", endset, unit);
  text(endsetText, graOriginX+graWidth-1, graOriginY+graHeight+16);  
    
  // time per division label
  textAlign(CENTER);
  float spd = getSecondPerDivision(prescaler);
  spd *= 1000.0;
  unit = "ms";
  if (spd < 0.001)
  {
    spd *= 1000.0;
    unit = "us";
  }
  String spdText = String.format("%.3f %s/div", spd, unit);
  text(spdText, graOriginX+graWidth/2, graOriginY+graHeight+32);  

  // volt per division label
  textAlign(RIGHT);
  float vpd = 5.0 / (graHeight / voltDivision);
  unit = "V";
  if (vpd < 0.001)
  {
    vpd *= 1000.0;
    unit = "mV";
  }
  String vpdText = String.format("%.3f %s/div", vpd, unit);
  text(vpdText, width-16, graOriginY+8);  

  // selected prescaler  
  String prescalerText = String.format("prescaler: %d", prescaler);
  text(prescalerText, width-16, graOriginY+8+32);  

  // selected threshold
  String thresholdText = String.format("threshold: %.1fV", threshold/256.0*5.0);
  text(thresholdText, width-16, graOriginY+8+48);  

  // selected offset
  float offset = (n - waitduration) * sps * 1000.0;
  unit = "ms";
  if (offset < 0.001)
  {
    offset *= 1000.0;
    unit = "us";
  }
  String offsetText = String.format("time offset: %.3f %s", offset, unit);
  text(offsetText, width-16, graOriginY+8+64);  
  
  // acquisition
  String acquisitionText = String.format("sampling: %s", sampling ? "ON" : "OFF");
  text(acquisitionText, width-16, graOriginY+graHeight-1);  
}

void drawMarker()
{
  int i = mouseX - graOriginX;
  if (i<0) i = 0;
  if (i>=n) i = n-1;

  // marker box
  stroke(255, 0, 0, 192.0);
  fill(97, 195, 97, 192.0); // green
  int x = i;
  int y = getY(samples[i]);
  ellipse(x+graOriginX, y+graOriginY, 8, 8);

  // marker line
  strokeWeight(2);
  stroke(255, 0, 0, 192.0);
  dottedLine(x+graOriginX, graOriginY, x+graOriginX, graOriginY+graHeight-1, 4);

  // marker text
  textAlign(RIGHT);
  fill(97, 195, 97, 255.0); // green
  float amplitude = (samples[i]/256.0 * 5.0) - voltageOffset;
  String markerAmpText = String.format("marker: %.3fV", amplitude);
  text(markerAmpText, width-16, graOriginY+8+80);  

  float time = getSecondPerSample(prescaler) * (i - (n - waitduration)) * 1000.0;
  String unit = "ms";
  if (time < 0.001)
  {
    time *= 1000.0;
    unit = "us";
  }
  String markerTimeText = String.format("marker: %.3f %s", time, unit);
  text(markerTimeText, width-16, graOriginY+8+96);
}

void drawButtons()
{
  strokeWeight(2);
  stroke(97, 195, 97, 255.0);
  noFill();
  
  startButton.draw();
  stopButton.draw();
}

void mousePressed()
{
  if (startButton.isPressed(mouseX, mouseY))
     {
      sampling = true;
      if (simulation) jitter = true;
     }
  if (stopButton.isPressed(mouseX, mouseY))
     {
      sampling = false;
      if (simulation) jitter = false;
     }
}

void dottedLine(float x1, float y1, float x2, float y2, float spacing)
{
  float steps = dist(x1, y1, x2, y2) / spacing;
  for (int i = 0; i <= steps; i++) 
  {
    float x = lerp(x1, x2, i/steps);
    float y = lerp(y1, y2, i/steps);
    point(x, y);
  }
}

float getSecondPerDivision(int prescaler)
{
  return getSecondPerSample(prescaler) * timeDivision;
}

float getSecondPerSample(int prescaler)
{
  // return the time duration of a sample according to calibration
  switch(prescaler)
  {
    case 32: // 50822 S/s with prescaler 32
      return 1.0/50822.0; // TBD
    case 64: // 14532 S/s with prescaler 64
      return 1.0/14532.0; // TBD
    case 128: // 9611 S/s with prescaler 128
    default :
      return 1.0/9611.0;
  } 
}

void keyReleased() {
  switch (key) {
    case '1':
      port.write("p2");
      break;
    case '2':
      port.write("p4");
      break;
    case '3':
      port.write("p8");
      break;
    case '4':
      port.write("p16");
      break;
    case '5':
      prescaler = 32;
      port.write("p32");
      break;
    case '6':
      prescaler = 64;
      port.write("p64");
      break;
    case '7':
      prescaler = 128;
      port.write("p128");
      break;
    case 't': // increase threshold by 0.1V
      threshold += 0.1/5.0 * 256.0;
      if (threshold >= 256) threshold=255;
      port.write("t" + Integer.toString(threshold));
      break;
    case 'g': // decrease threshold by 0.1V
      threshold -= 0.1/5.0 * 256.0;
      if (threshold <= 0) threshold=1;
      port.write("t" + Integer.toString(threshold));
      break;
    case 'y': // increase by 16 samples the pre-trigger duration
      waitduration += 16;
      if (waitduration > n) waitduration=n;
      port.write("w" + Integer.toString(n - waitduration));
      break;
    case 'h': // decrease by 16 samples the pre-trigger duration
      waitduration -= 16;
      if (n - waitduration > 992) waitduration= n - 992;
      port.write("w" + Integer.toString(n - waitduration));
      break;
    case 's': // start the sampling process
      sampling = true;
      port.write(key);
      if (simulation) jitter = true;
      break;
    case 'x': // stop the sampling process
      sampling = false;
      port.write(key);
      if (simulation) jitter = false;
      break;
    case '+':
      zoom *= 2.0f;
      println(zoom);
      if ( (int) (width / zoom) <= 1 )
        zoom /= 2.0f;
      break;
    case '-':
      zoom /= 2.0f;
      if (zoom < 1.0f)
        zoom *= 2.0f;
      break;
  }
}
 
void draw()
{
  background(0);
  getBuffer();
  drawGrid();
  drawTexts();
  drawButtons();
  drawSignal();
  drawMarker();
}



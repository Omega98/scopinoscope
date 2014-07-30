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

int threshold;
int prescaler;
 
void setup() 
{
  // Open the port that the board is connected to and use the same speed (9600 bps)
  port = new Serial(this, Serial.list()[0], 115200);

  n = 1280;
  samples = new int[n];

  int graTopSpacing = 16;
  int graBottomSpacing = 64;
  int graLeftSpacing = 16;
  int graRightSpacing = graLeftSpacing;
  
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

  threshold = 10;
  prescaler = 128;
}
 
int getY(int val) {
  return (int)(graHeight - val / 255.0f * (graHeight - 1));
}
 
void getBuffer() {
  if (simulation)
  {
    float f = random(10.0*16.0-0.8, 10.0*16.0+0.5);
    float a = random(2.22, 2.27);
    for (int i=0; i<n; i++)
      pushValue(int( ((a*sin(TWO_PI*i/f))+2.50)/5.0*256.0 ));
  }
  else
  {
    while (port.available() >= n) {
      if (port.read() == 0xff) {
        /* value = (port.read() << 8) | (port.read()); */
        for (int i=0; i<n; i++)
          pushValue(port.read());
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

  // Y-Axis - todo place origin?
  dottedLine(graOriginX+graWidth/2, graOriginY, graOriginX+graWidth/2, graOriginY+graHeight-1, dotStyle);
  
  // Small crossbars on x-axis
  for (int x=graOriginX; x<graOriginX+n; x+=smallTimeDivision*zoom)
  {
    line(x, graOriginY+graHeight/2-2, x, graOriginY+graHeight/2+2);
  }

  // Small crossbars on y-axis
  for (int y=graOriginY; y<graOriginY+graHeight-1; y+=smallVoltDivision)
  {
    line(graOriginX+graWidth/2-2, y, graOriginX+graWidth/2+2, y);
  }

  // Division bars crossing x-axis i.e. |||
  for (int x=graOriginX; x<graOriginX+graWidth-1; x+=timeDivision*zoom)
  {
    dottedLine(x, graOriginY, x, graOriginY+graHeight-1, 16);
  }
  
  // Division bars crossing y-axis i.e. = =
  for (int y=graOriginY; y<graOriginY+graHeight-1; y+=voltDivision)
  {
    dottedLine(graOriginX, y, graOriginX+graWidth-1, y, smallTimeDivision*zoom);
  }
  
  // Frame
  strokeWeight(4);
  noFill();
  rect(graOriginX-1, graOriginY-1, graWidth+1, graHeight+1); 
}

void dottedLine(float x1, float y1, float x2, float y2, float spacing){
 float steps = dist(x1, y1, x2, y2) / spacing;
 for (int i = 0; i <= steps; i++) {
  float x = lerp(x1, x2, i/steps);
  float y = lerp(y1, y2, i/steps);
  point(x, y);
 }
}

float getUsPerDivision(int prescaler)
{
  return 0.0;
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
      port.write("p32");
      break;
    case '6':
      port.write("p64");
      break;
    case '7':
      port.write("p128");
      break;
    case 't':
      threshold++;
      if (threshold >= 256) threshold=255;
      port.write("t" + Integer.toString(threshold));
      break;
    case 'g':
      threshold--;
      if (threshold < 0) threshold=1;
      port.write("t" + Integer.toString(threshold));
      break;
    case 's':
      port.write(key);
      break;
    case 'x':
      port.write(key);
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
  drawGrid();
  getBuffer();
  drawSignal();
}



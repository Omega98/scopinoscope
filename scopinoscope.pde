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
 
Serial port;  // Create object from Serial class
int val;      // Data received from the serial port
int[] values;
float zoom;
int n; 
int threshold;
 
void setup() 
{
  n = 1280;
  threshold = 10;
  size(n, 480);
  // Open the port that the board is connected to and use the same speed (9600 bps)
  port = new Serial(this, Serial.list()[0], 115200);
  values = new int[n];
  zoom = 1.0f;
  smooth();
}
 
int getY(int val) {
  return (int)(height - val / 255.0f * (height - 1));
}
 
int getValue() {
  int value = -1;
  while (port.available() >= n) {
    if (port.read() == 0xff) {
      /* value = (port.read() << 8) | (port.read()); */
      for (int i=0; i<n; i++)
        pushValue(port.read());
    }
  }
  return value;
}
 
void pushValue(int value) {
  for (int i=0; i<width-1; i++)
    values[i] = values[i+1];
  values[width-1] = value;
}
 
void drawLines() {
  stroke(255);
  
  int displayWidth = (int) (width / zoom);
  
  int k = values.length - displayWidth;
  
  int x0 = 0;
  int y0 = getY(values[k]);
  for (int i=1; i<displayWidth; i++) {
    k++;
    int x1 = (int) (i * (width-1) / (displayWidth-1));
    int y1 = getY(values[k]);
    line(x0, y0, x1, y1);
    x0 = x1;
    y0 = y1;
  }
}
 
void drawGrid() {
  stroke(255, 0, 0);
  line(0, height/2, width, height/2);
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
  val = getValue();
  /*if (val != -1) {
    pushValue(val);
  }*/
  drawLines();
}



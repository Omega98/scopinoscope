class Button
{
  private int x;
  private int y;
  private int w;
  private int h;
  private String label;
  private int alignment;
  
  Button(String s, int x0, int y0, int width, int height, int align)
  {
    label = s;
    x = x0;
    y = y0;
    w = width;
    h = height;
    alignment = align;
  }
  
  void draw()
  {
    rect(x, y, w, h);
    rect(x+2, y+2, w-4, h-4);
    textAlign(alignment);
    text(label, x+w/2, y+h/2+8);  
  }
  
  boolean isPressed(int mouseX, int mouseY)
  {
    if ((mouseX > x) &&
        (mouseX < x+w) &&
        (mouseY > y) &&
        (mouseY < y+h))
       {
        return true;
       }
    return false;
  }  
  
  
}

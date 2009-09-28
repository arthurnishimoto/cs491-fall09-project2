import java.util.ArrayList;

import processing.core.*;


public class MTScrollBar extends PApplet{
  /**
   * 	 * 
   	 */
  private static final long serialVersionUID = 1L;

  final static int VERTICAL = 0;
  final static int HORIZONTAL = 1;
  int TYPE = -1;

  float xPos, yPos, barWidth, barHeight;
  float buttonWidth = 100;
  float currentPosition; // Button position 0.0-1.0
  float buttonPosition; // Button position - actual x,y
  float screenScale;
  PApplet p;
  PFont font;

  boolean buttonsEnabled = true;

  MTButton upButton, downButton;

  // bar in centered on given x,y
  public MTScrollBar(PApplet parent, float x, float y, float width, float height){
    xPos = x;
    yPos = y;
    barWidth = width;
    barHeight = height;

    if( barWidth > barHeight ){
      TYPE = HORIZONTAL;
      yPos = y - barHeight/2;

      upButton = new MTButton(parent, x + barHeight/2, y, barHeight, barHeight);
      upButton.setIdleColor(color(178,178,178));
      upButton.setButtonText("<");
      upButton.setDoubleSidedText(false);
      downButton = new MTButton(parent, x + barWidth - barHeight/2, y, barHeight, barHeight);
      downButton.setIdleColor(color(178,178,178));
      downButton.setButtonText(">");
      downButton.setDoubleSidedText(false);

    }
    else if( barWidth < barHeight ){
      TYPE = VERTICAL;
      xPos = x - barWidth/2;
      yPos = y;

      upButton = new MTButton(parent, x, y + barWidth/2 , barWidth, barWidth);
      upButton.setIdleColor(color(178,178,178));
      upButton.setButtonText("<");
      upButton.setDoubleSidedText(false);
      downButton = new MTButton(parent, x, y-barWidth/2+barHeight , barWidth, barWidth);
      downButton.setIdleColor(color(178,178,178));
      downButton.setButtonText(">");
      downButton.setDoubleSidedText(false);

      upButton.setRotation(radians(90));
      downButton.setRotation(radians(90));

    }// if-else

    p = parent;
    currentPosition = 0;
    screenScale = (float) 1.0;

    font = p.createFont("Helvetica", 12);

  }// CTOR

  public void draw(){
    // Display bar
    p.fill(color(218,218,218));
    p.stroke(color(218,218,218));
    if(TYPE == VERTICAL)
      p.rect(xPos, yPos+barWidth, barWidth, barHeight-barWidth*2);
    else if(TYPE == HORIZONTAL)
      p.rect(xPos, yPos, barWidth, barHeight);

    if(buttonsEnabled){
      upButton.process();
      downButton.process();
    }

    // Display scroll button
    p.fill(50,50,50);
    p.stroke(120,120,120);
    if(TYPE == VERTICAL){
      p.rect(xPos, buttonPosition, barWidth, barWidth);
      buttonPosition = yPos + barWidth + currentPosition*(barHeight-barWidth*3);
    }
    else if(TYPE == HORIZONTAL){
      p.rect(buttonPosition, yPos, barHeight, barHeight);
      buttonPosition = xPos + barHeight + currentPosition*(barWidth-barHeight*3);
    }
  }// display

  public void displayDebug(){
    p.fill(0,0,0);
    p.textFont(font,16);

    p.text("Current Position: "+currentPosition, xPos+barWidth, yPos);
  }// displayDebug

  public boolean isPressed( float xCoord, float yCoord ){
    boolean pressed = false;
    
    if( xCoord > xPos && xCoord < xPos + barWidth && yCoord > yPos && yCoord < yPos + barHeight){
      //p.fill(255,0,0);
      //p.ellipse(xCoord,yCoord, 10, 10);
      float touchPos;

      switch(TYPE){
        case(HORIZONTAL):
        touchPos = (xCoord - xPos - 3*barHeight/2); // Relative to the lowest button pos

        // Prevents moving bar outside of up/down/scroll buttons
        //if( xCoord > buttonPosition && xCoord < buttonPosition + barHeight )
          if( touchPos > 0 && touchPos/(barWidth - barHeight*3) <= 1.0 ){
            //println( (xCoord - xPos - 3*barHeight/2)+" "+(barWidth - barHeight*3) );
            currentPosition = touchPos/(barWidth - barHeight*3);
            pressed = true;
          }// if
        break;
        case(VERTICAL):
        touchPos = (yCoord - yPos - 3*barWidth/2); // Relative to the lowest button pos

        // Prevents moving bar outside of up/down/scroll buttons
        //if( yCoord > buttonPosition && yCoord < buttonPosition + barWidth )
          if( touchPos > 0 && touchPos/(barHeight - barWidth*3) <= 1.0 ){
            //println( touchPos+" "+(barHeight - barWidth*3) );
            currentPosition = touchPos/(barHeight - barWidth*3);
            pressed = true;
          }// if
        break;
      }// switch

      if( upButton.isButtonHit(xCoord,yCoord) ){
        if(currentPosition - 0.1 >= 0)
          currentPosition -= 0.1;
        else
          currentPosition = 0;
        pressed = true;
      }
      
      if( downButton.isButtonHit(xCoord,yCoord) ){
        if(currentPosition + 0.1 <= 1)
          currentPosition += 0.1;
        else
          currentPosition = 1;
        pressed = true;
      }
    }//if touching on bar

    return pressed;
  }// isPressed

  public boolean isMouseOver( float xCoord, float yCoord ){
    if( xCoord > xPos && xCoord < xPos + barWidth && yCoord > yPos && yCoord < yPos + barHeight)
      return true;
    else
      return false;
  }// isMouseOver

  public void setScreenScale(float newScale){
    screenScale = newScale;
  }// setScreenScale

  /***
   * 	 * Returns the scroll button position on a scale from 0.0 to 1.0
   * 	 * @return float currentPosition Current position of scroll button (0.0-1.0)
   	 */
  public float getCurrentPosition(){
    return currentPosition;
  }// getCurrentPosition

  /***
   * 	 * Sets the scroll button position. Must be 0.0 to 1.0
   * 	 * @param newValue New scroll button position
   	 */
  public void setCurrentPosition(float newValue){
    if( newValue < 0 || newValue > 1 )
      return;
    currentPosition = newValue;
  }// getCurrentPosition

}// class MTScrollBar




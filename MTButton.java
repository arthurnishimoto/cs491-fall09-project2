
import java.util.ArrayList;

import processing.core.*;

/**
 * ---------------------------------------------
 * MTButton.java
 *
 * Description: Simple button class. Either uses a rectangle, rectangular image or a circle
 *
 * Class:
 * System: Processing 1.0.1 / Eclipse 3.4.1, Windows XP SP2/Windows Vista/Ubuntu 9.10/OpenSUSE 11.1
 * Author: Arthur Nishimoto
 * Version: 0.4.2
 * 
 * Version Notes:
 * 2/6/09   - Initial version
 * 3/28/09  - Added button text
 * 4/1/09   - Support for rectangular buttons
 *          - Button text displays up and down
 * 4/4/09   - Added a lit state
 * 4/26/09  - Version 0.2
 *          - Added litImage and rotation for circle, rect, and images. (hitBox does not rotate)
 * 4/29/09  - Font size added.
 * 6/1/09   - Version 0.2.1
 *          - Added push delay to allow a hold-press
 * 6/4/09   - Button uses internal timer
 * 6/5/09   - Version 0.3.1
 *          - Null pointer bug fix (make sure all Processing draw functions (i.e. fill, stroke, text) point to PApplet p.
 *          - Additional support for rectangular buttons with/without images.
 * 6/15/09  - Version 0.3.2
 *          - Delay mode on longer default. Older constructors not using PApplet removed.
 *          - All delay data/methods renamed to hold.
 * 6/22/09  - Version 0.4
 * 			- checkTouchList added for better touch detection internally checks list.
 * 			- Hold style 0 correctly draws growing circle to proper size.
 * 			- Fixed rectangle and image debug text location	
 *          - Rectangle now can use holdPress (rectangle style 0 and 1 added)
 * 6/25/09  - Version 0.4.1
 * 			- checkTouchList now properly checks touches.
 * 7/6/09   - No longer presses using last touch from touchList
 * 7/16/09  - isHit(x,y,finger) should now support the same finger ID tracking as checkTouchList()
 * 7/21/09  - Added setScreenScale to allow touches to correctly scale with screen. isHit(x,y,f) implementation bugged (touch releases and isPressed issue)
 * 7/22/09  - ButtonDownTime properly ignores touches during downtime when using checkTouchList()
 *          - isHit(x,y,f) issues resolved. Properly tracks how many touches on a button using isHit(x,y,f) or checkTouchList(touchList).
 * 7/24/09  - Version 0.4.2
 *          - Buttons can now be scaled. Display, Image, Holds, Touches all taken in account. If screen is scaled, must use setScreenScale() to fix touch positions
 * ---------------------------------------------
 */

public class MTButton extends PApplet{
        boolean mouse_touch_override = true;
  
        final static int ACTIVE = 2; // Active state - displays and accepts inputs
        final static int INACTIVE = 1; // Inactive state - displays but does not accept input. May be in a fade state.
        final static int DISABLED = 0; // Disabled - not displayed, not input. Fade commands ignored. Only activated using setActive/setInactive
        int STATE = INACTIVE;
        
	PApplet p;
        float screenScale = 1;
        float buttonScale = 1;
        
	PImage buttonImage;
	float xPos, yPos;
	double buttonDownTime = 0.2;
	double buttonLastPressed = -1; // 0 if delay desired (First press ignored), -1 for initially ready (default)
	double gameTimer;
	boolean hasImage = false;
	boolean isRound = false;
	boolean isRectangle = false;
	boolean pressed, lit;
	float diameter;
	float rHeight, rWidth;
	int idle_cl = color( 0, 0, 0 );
        int stroke_idle_cl = color( 0, 0, 0 );
	int lit_cl = color( 255, 255, 255 );
        int stroke_lit_cl = color( 255, 255, 255 );
	int pressed_cl = color( 255, 0, 0);
        int stroke_pressed_cl = color( 255, 0, 0 );
	float angle = 0;
	int fontSize = 16;
        float rotation = 0;

	boolean hasLitImage = false;
	PImage litImage;
	  
	boolean hasPressedImage = false;
	PImage pressedImage;

	String buttonText = "";
	String secondaryText = "";
	int buttonTextColor = color(0,0,0);
	int secondaryTextColor = color(0,0,0);
	boolean doubleSidedText = true;
	boolean invertText = false;
	  
	int fadeAmount = 1;
	int fadeSpeed = 5;
	boolean fadeIn, fadeOut;
	int fadeColor = color(0,0,0);
	boolean fadeEnable = false;
	boolean doneFading = true;
	  
	boolean holdPress = false;
	float holdCounter = 0;
	float holdIncrement = 1;
	float holdTrigger = 100;
	int holdStyle = 0;
	PFont font;

        ArrayList<Integer> fingerIDs = new ArrayList<Integer>();	

	public final String VERSION = "0.4.2";

	/**
	 * return the version of the library.
	 * 
	 * @return String
	 */
	public String version() {
		return VERSION;
	}

	/**
	 * Creates a new round button, (x,y) is center. Used when button is not created
	 * inside the parent Processing class.
     *
     * @param parent PApplet parent where draw() is called
	 * @param new_xPos x position
	 * @param new_yPos y position
	 * @param newDia diameter
	 */
	public MTButton( PApplet parent, float new_xPos, float new_yPos, float newDia ){
	  p = parent;
	  diameter = newDia;

	  rWidth = diameter;
	  rHeight = diameter;
	  xPos = new_xPos;
	  yPos = new_yPos;
	  isRound = true;
          font = p.loadFont("CourierNew36.vlw");
	}// Button CTOR
	
	/**
	 * Creates a new rectangular button, (x,y) is center.
	 * Used when button is not created inside the parent Processing class.
	 *
	 * @param parent PApplet parent where draw() is called
	 * @param new_xPos x position
	 * @param new_yPos y position
	 * @param newWidth  - width
	 * @param newHeight - height
	 */
	public MTButton( PApplet parent, float x, float y, float newWidth, float newHeight ){
	  p = parent;
	  rWidth = newWidth;
	  rHeight = newHeight;
	  diameter = newWidth;
	  xPos = x;
	  yPos = y;
	  isRectangle = true;
          font = p.createFont("Helvetica", 12);
	}// Button CTOR
	
	/**
	 * Creates a new rectangular button with an image, (x,y) is center.
	 * Used when button is not created inside the parent Processing class.
	 *
	 * @param parent PApplet parent where draw() is called
	 * @param new_xPos x position
	 * @param new_yPos y position
	 * @param newImage PImage to be displayed as idle image
	 */  
	public MTButton( PApplet parent, float new_xPos, float new_yPos, PImage newImage, boolean isButtonRound ){
	  p = parent;
	  buttonImage = newImage;
	  rWidth = buttonImage.width;
	  rHeight = buttonImage.height;
          if( isButtonRound ){
            if( rWidth >= rHeight )
              diameter = rWidth;
            else
              diameter = rHeight;
          }
	  xPos = new_xPos;
	  yPos = new_yPos;
	  hasImage = true;
          isRound = isButtonRound;
          font = p.loadFont("CourierNew36.vlw");
	}// Button CTOR
	
	/**
	 * Sets button active, displays, updates timer.
	 * Uses internal Processing timer.
	 * @param font Font the button will use to display text. If null, button has a default font.
	 */
	public void process(PFont font){
          if( STATE == DISABLED )
            return;
	  if(hasImage)
	    displayImage();
	  else
	    display(font);
	  displayText();
	  displaySecondaryText();
	  //displayDebug(color(0,255,0), font);
	  //displayEdges(color(255,255,255));
	  setGameTimer((double)millis()/1000);
	}// process
	
	/**
	 * Sets button active, displays, updates timer.
	 * @param font Font the button will use to display text. If null, button has a default font.
	 * @param timer_g The timer used for determining press time. Taken from the game loop.
	 */
	public void process(PFont font, double timer_g){
          if( STATE == DISABLED )
            return;
            
	  if(hasImage)
	    displayImage();
	  else
	    display(font);
	  displayText();
	  displaySecondaryText();
	  //displayDebug(color(0,255,0), font);
	  //displayEdges(color(255,255,255));
	  setGameTimer(timer_g);
	}// process
	
	/**
	 * Sets button active, displays, updates timer.
	 */
	public void process(){
          if( STATE == DISABLED )
            return;
            
	  if(hasImage)
	    displayImage();
          else
            display(font);
          displayHold();	  
          displayText();
	  displaySecondaryText();
	  //displayDebug(color(0,255,0), font);
	  //displayEdges(color(255,255,255));
	  setGameTimer((double)millis()/1000);

          if( !pressed )
            fingerIDs.clear();
	}// process
	
        public void setButtonScale( float scaleValue){
          buttonScale = scaleValue;
        }
  
	/**
	 * Secondary text field that displays text in the upper left corner - Rotation NOT supported.
	 */
	private void displaySecondaryText(){
		  p.pushMatrix();
		  p.translate(xPos - rWidth/2 + fontSize/2 , yPos - rHeight/2 + fontSize/2 + 3);
		  p.rotate( rotation );
		  
		  
		  p.fill(buttonTextColor, 50);
		  p.textFont(font,fontSize);
		  p.textAlign(CENTER);
		  
		  p.text(secondaryText, 0, 0);
		  
		  p.textAlign(LEFT);
		  p.popMatrix();
	}// displaySecondaryText()
	
	private void displayImage(){
	  if( fadeAmount <= 1 )
	    STATE = ACTIVE;

	  if(fadeEnable){
	    if(fadeIn && fadeAmount > 0)
	      fadeAmount -= fadeSpeed;
	    else if(fadeOut && fadeAmount < 256)
	      fadeAmount += fadeSpeed;
	    else
	      doneFading = true;
	  }// if fadeEnable
	    
	  p.imageMode(CENTER);
	  p.pushMatrix();
	  p.translate(xPos, yPos);
          p.scale( buttonScale );
	  p.rotate( rotation );
	  p.tint(255,255,255, 255-fadeAmount);
	  p.image( buttonImage, 0, 0);
	  if( hasLitImage && lit )
	    p.image( litImage, 0, 0 );
	  if( hasPressedImage && pressed )
	    p.image( pressedImage, 0, 0 );
	    
	  p.popMatrix();
	  p.imageMode(CORNER);
	}// displayImage
	 
	private void displayText(){
	  p.pushMatrix();
	  p.translate(xPos, yPos);
	  p.rotate( rotation );
	  p.scale( buttonScale );
	  
	  p.fill(buttonTextColor);
	  p.textFont(font,fontSize);
	  p.textAlign(CENTER);
	
	  int textShift = 4;
	  if( doubleSidedText )
	    textShift = fontSize;
	  
	  if( doubleSidedText || !invertText ){
	    p.text(buttonText, 0, 0 + textShift);
	  }// if text not inverted
	    
	    if( doubleSidedText || invertText ){
	      p.translate(0, 0 - textShift);
	      p.rotate(radians(180));
	      p.text(buttonText, 0, 0);  
	      
	    }// if doubleSidedtext
	    p.textAlign(LEFT);
	    p.popMatrix();
	  }// displayText
	
	  private void display(PFont font){
	    p.rectMode(CENTER);
	    p.pushMatrix();
	    p.translate(xPos, yPos);
	    p.rotate( rotation );
	    p.scale( buttonScale );

	    if( fadeAmount <= 1 )
	      STATE = ACTIVE;
	    
	    if(!pressed && !lit){
	      p.fill(idle_cl, 255-fadeAmount);
	      p.stroke(stroke_idle_cl, 255-fadeAmount);
	      if(isRound)
	        p.ellipse( 0, 0, diameter, diameter );
	      else if(isRectangle)
	        p.rect( 0, 0, rWidth, rHeight );
	    }else if(lit){
	      p.fill(lit_cl, 255-fadeAmount);
	      p.stroke(stroke_lit_cl, 255-fadeAmount);
	      if(isRound)
	        p.ellipse( 0, 0, diameter, diameter );
	      else if(isRectangle)
	        p.rect( 0, 0, rWidth, rHeight );
	    }else if(pressed){
	      p.fill(pressed_cl, 255-fadeAmount);
	      p.stroke(stroke_pressed_cl, 255-fadeAmount);
	      if(isRound)
	        p.ellipse( 0, 0, diameter, diameter );
	      else if(isRectangle)
	        p.rect( 0, 0, rWidth, rHeight );
	    }

	    if(fadeEnable){
	      if(fadeIn && fadeAmount > 0)
	        fadeAmount -= fadeSpeed;
	      else if(fadeOut && fadeAmount < 256)
	        fadeAmount += fadeSpeed;
	      else
	        doneFading = true;
	    }// if fadeEnable

	    p.popMatrix();
	    p.rectMode(CORNER);
	  }// display
	  
	  /**
	   * Displays the hitbox edges of button
	   *
	   * @param debugColor - color of edges
	   */
	  public void displayEdges(int debugColor){
	    p.fill(debugColor);
            p.pushMatrix();
            p.translate(xPos,yPos);
            p.scale(buttonScale);
            float orig_xPos = xPos;
            float orig_yPos = yPos;
            xPos = 0;
            yPos = 0;
	    if(isRound){
	      p.ellipse( xPos-diameter/2, yPos-diameter/2, 10, 10 ); // Top left
	      p.ellipse( xPos+diameter/2, yPos-diameter/2, 10, 10 ); // Top Right
	      p.ellipse( xPos-diameter/2, yPos+diameter/2, 10, 10 ); // Bottom left
	      p.ellipse( xPos+diameter/2, yPos+diameter/2, 10, 10 ); // Bottom Right      
	    }else if(hasImage){
	      p.ellipse( xPos-buttonImage.width/2, yPos-buttonImage.height/2, 10, 10 ); // Top left
	      p.ellipse( xPos+buttonImage.width/2, yPos+buttonImage.height/2, 10, 10 ); // Bottom Right
	      p.ellipse( xPos+buttonImage.width/2, yPos-buttonImage.height/2 , 10, 10 ); // Top right
	      p.ellipse( xPos-buttonImage.width/2, yPos+buttonImage.height/2, 10, 10 );// Bottom Left 
	    }else if(isRectangle){
	      p.ellipse( xPos-rWidth/2, yPos-rHeight/2, 10, 10 ); // Top left
	      p.ellipse( xPos+rWidth/2, yPos+rHeight/2, 10, 10 ); // Bottom Right
	      p.ellipse( xPos+rWidth/2, yPos-rHeight/2 , 10, 10 ); // Top right
	      p.ellipse( xPos-rWidth/2, yPos+rHeight/2, 10, 10 );// Bottom Left    
	    }
            p.popMatrix();
            xPos = orig_xPos;
            yPos = orig_yPos;
	  }//  displayEdges
	  
	  public void displayDebug(int debugColor, PFont font){
	    p.fill(debugColor);
	    p.textFont(font,16);

	    p.text("Pressed: "+pressed, xPos+rWidth/2, yPos-rHeight/2);
	    if( holdPress ){
	    	p.text("Hold Incrementer: "+holdIncrement, xPos+rWidth/2, yPos-rHeight/2+16);
	    	p.text("Hold Counter: "+holdCounter+"/"+holdTrigger, xPos+rWidth/2, yPos-rHeight/2+16*2);
	    }else{
	    	p.text("Button Delay: "+buttonDownTime, xPos+rWidth/2, yPos-rHeight/2+16);
		    if(buttonLastPressed + buttonDownTime > gameTimer)
		    	p.text("Button Downtime Remain: "+((buttonLastPressed + buttonDownTime)-gameTimer), xPos+rWidth/2, yPos-rHeight/2+16*2);
		    else
		    	p.text("Button Downtime Remain: 0", xPos+rWidth/2, yPos-rHeight/2+16*2);
	    }
	    //p.text("Internal Timer: "+gameTimer, xPos+rWidth, yPos-rHeight/2+16*3);

            p.text("Diameter: "+diameter+" (scaled to: "+diameter*buttonScale+" by factor "+buttonScale+")", xPos+rWidth/2, yPos-rHeight/2+16*5);
            p.text("Touch Test: <minHit, actual, maxHit>: x <"+xMin+","+xHit+","+xMax+">", xPos+rWidth/2, yPos-rHeight/2+16*6);
            p.text("Touch Test: <minHit, actual, maxHit>: y <"+yMin+","+yHit+","+yMax+">", xPos+rWidth/2, yPos-rHeight/2+16*7);
	  }// displayDebug
	  
	  /**
	   * Checks if the given (x,y) coordinate is inside the button and then processes the press if true - Only be used for mouse input.
	   * Touches should use checkTouchList(ArrayList). Not to be confused with checkButtonHit, which only returns a boolean and does not process the press.
	   * 
	   * @param xCoord x coordinate
	   * @param yCoord y coordinate
	   * @return if x,y coordinate is inside the button
	   */
	  public boolean isHit( float xCoord, float yCoord, int finger ){
                    if( STATE == DISABLED )
                      return false;
            
                    boolean hit = false;

		    if( STATE != ACTIVE || fadeAmount > 1 )
			      return false;

                    if( isButtonHit(xCoord,yCoord) ){
                      boolean uniqueID = true;
          	      for ( int index2 = 0; index2 < fingerIDs.size(); index2 ++ ){
          		if( finger == fingerIDs.get(index2) ){
          		  uniqueID = false;
          	        }// if fingerID already exists
          	      }// for touches
                      if(uniqueID)
          		fingerIDs.add(finger);
                      hit = true;
          	    }else{
                      if( fingerIDs.indexOf(finger ) != -1 )
                       fingerIDs.remove( fingerIDs.indexOf(finger) );
                      hit = false;
                      resetButton();
                      fingerIDs.clear();
                    }
                    if( fingerIDs.size() > 0 )
                      pressButton();
                    else
                      resetButton();
                    return hit;
	  }// isHit
	  
	  /**
	   * Checks if the given x,y coordinates are inside the button. Not to be confused with isHit() which also returns a boolean, but also processes the press.
	   * Used internally for checkTouchList or for mouse-over checking.
	   * 
	   * @param xCoord x coordinate
	   * @param yCoord y coordinate
	   * @return if x,y coordinate is inside the button
	   */
          float xHit, yHit, xMax, xMin, yMax, yMin;
	  public boolean isButtonHit( float xCoord, float yCoord ){
            xHit = xCoord;
            yHit = yCoord;
            xMax = xPos+(diameter*buttonScale)/2;
            xMin = xPos-(diameter*buttonScale)/2;
            yMin = yPos-(diameter*buttonScale)/2;
            yMax = yPos+(diameter*buttonScale)/2;
            if( STATE != ACTIVE || fadeAmount > 1 )
	      return false;
                           
	    if(isRound){
              if( xCoord > xPos-(diameter*buttonScale)/2 && xCoord < xPos+(diameter*buttonScale)/2 && yCoord > yPos-(diameter*buttonScale)/2 && yCoord < yPos+(diameter*buttonScale)/2){
	        return true;
	      }// if x, y in area
	    }else if(hasImage){
	      if( xCoord > xPos-(buttonImage.width*buttonScale)/2 && xCoord < xPos+(buttonImage.width*buttonScale)/2 && 
                yCoord > yPos - (buttonImage.height*buttonScale)/2  && yCoord < yPos+(buttonImage.height*buttonScale)/2){
	               return true;
	      }// if x, y in area
	    }else if(isRectangle){
	       if( xCoord > xPos-(rWidth*buttonScale)/2 && xCoord < xPos+(rWidth*buttonScale)/2 && yCoord > yPos - (rHeight*buttonScale)/2  && yCoord < yPos+(rHeight*buttonScale)/2){
	               return true;
	      }// if x, y in area     
	    }
	    return false;
	  }// isButtonHit
	  
	  public boolean pressButton(){
		if( STATE != ACTIVE || fadeAmount > 1 )
		  return false;

                if(holdPress){
		  if( holdCounter >= holdTrigger ){
		    pressed = true;
		    return true;
		  }else{
		    holdCounter += holdIncrement;
		    return true;
		  }// if-else hold counter
		}// if holdPress
                
                if( ((buttonLastPressed + buttonDownTime)-gameTimer) <= 0 ){
                  buttonLastPressed = gameTimer;
                  pressed = true;
                  return true;
                }else if( ((buttonLastPressed + buttonDownTime)-gameTimer) > buttonDownTime ){
                  buttonLastPressed = gameTimer - buttonDownTime;
                  pressed = false;
                  return false;
                }
                pressed = false;
                return false;
          }// pressButton

		  
	  public void displayHold(){
            p.pushMatrix();
            p.translate(xPos,yPos);
            p.scale(buttonScale);
	    switch(holdStyle){
	      case(0):
	        p.fill(pressed_cl);
	        p.noStroke();
	        if(isRound)
	          p.ellipse( 0, 0, diameter*(holdCounter/holdTrigger), diameter*(holdCounter/holdTrigger) );
	        else if(isRectangle)
	          p.rect( 0, 0, rWidth*(holdCounter/holdTrigger), rHeight*(holdCounter/holdTrigger) );
	        break;
	      case(1):
	        p.fill(pressed_cl);
	        p.noStroke();
	        if(isRound || hasImage){
	          if( holdCounter/holdTrigger > 0 )
	            p.ellipse( 0, 0-diameter/2, diameter/10, diameter/10 );
	          if( holdCounter/holdTrigger > 0.15 )
	            p.ellipse( 0+diameter/3, 0-diameter/3, diameter/10, diameter/10 );
	          if( holdCounter/holdTrigger > 0.30 )
	            p.ellipse( 0+diameter/2, 0, diameter/10, diameter/10 );
	          if( holdCounter/holdTrigger > 0.45 )
	            p.ellipse( 0+diameter/3, 0+diameter/3, diameter/10, diameter/10 );
	          if( holdCounter/holdTrigger > 0.60 )
	            p.ellipse( 0, 0+diameter/2, diameter/10, diameter/10 );
	          if( holdCounter/holdTrigger > 0.75 )
	            p.ellipse( 0-diameter/3, 0+diameter/3, diameter/10, diameter/10 );
	          if( holdCounter/holdTrigger > 0.95 )
	            p.ellipse( 0-diameter/2, 0, diameter/10, diameter/10 );
	          if( holdCounter/holdTrigger >= 1.0 )
	            p.ellipse( 0-diameter/3, 0-diameter/3, diameter/10, diameter/10 );
	        }
	        else if(isRectangle){
	        	p.rectMode(p.CORNER);
	        	p.rect( 0-rWidth/2, 0-rHeight/2, rWidth*(holdCounter/holdTrigger), rHeight);
	        }
	        break;
	      default:
	        println("ERROR: Unknown button hold style.");
	        break;
	    }
            p.popMatrix();
	  }// displayHold
	  
	  public void resetButton(){
            holdCounter = 0;
	    pressed = false;
	  }// resetButton;
	  
	  // Setters and Getters
	  public void setIdleColor(int newColor){
	    idle_cl = newColor;
            stroke_idle_cl = newColor;
	  }// setIdleColor
	  
	  public void setIdleColor(int newColor, int strokeColor){
	    idle_cl = newColor;
            stroke_idle_cl = strokeColor;
	  }// setIdleColor
	  
	  public void setLitColor(int newColor){
	    lit_cl = newColor;
            stroke_lit_cl = newColor;
	  }// setLitColor

	  public void setLitColor(int newColor, int strokeColor){
	    lit_cl = newColor;
            stroke_lit_cl = strokeColor;
	  }// setLitColor

	  public void setLitImage(PImage newImage){
	    litImage = newImage;
	    hasLitImage = true;
	  }// setLitImage  
	  
	  public void setLit(boolean newBool){
	    lit = newBool;
	  }// setLit
	  
	  public void setPressedColor(int newColor){
	    pressed_cl = newColor;
            stroke_pressed_cl = newColor;
	  }// setPressedColor
	  
          public void setPressedColor(int newColor, int strokeColor){
	    pressed_cl = newColor;
            stroke_pressed_cl = strokeColor;
	  }// setPressedColor

	  public void setPressedImage(PImage newImage){
	    pressedImage = newImage;
	    hasPressedImage = true;
	  }// setPressedImage  
	  
	  public void setButtonText(String newText){
	    buttonText = newText;
	  }// setButtonText  
	  
          public void setTextFont(PFont newFont){
	    font = newFont;
	  }// setsTextFont

	  public void setSecondaryText(String newText){
		secondaryText = newText;
	  }// setSecondaryText
	  
	  public void setButtonText(String newText, int newColor){
		  buttonText = newText;
		  buttonTextColor = newColor;
	  }// setButtonText 
	  
	  public void setButtonTextSize(int newSize){
	    fontSize = newSize;
	  }// setButtonTextSize
	  
	  public void setButtonTextColor(int newColor){
	    buttonTextColor = newColor;
	  }// setButtonTextColor
	  
	  public void setSecondaryTextColor(int newColor){
		  secondaryTextColor = newColor;
	  }// setSecondaryTextColor
	  
	  public void setDoubleSidedText( boolean newBool ){
	    doubleSidedText = newBool;
	  }// setDoubleSidedText
	  
	  public void setInvertedText( boolean newBool ){
	    invertText = newBool;
	    doubleSidedText = !newBool;
	  }// setInvertedText
	  
	  public void setDelay(double newDelay){
	    buttonDownTime = newDelay;
	  }// setDelay

	  /*
	   * If true, button can be pressed on start. Could accidently press if there are multiple buttons on the same location of adjacent screens
	   * If false, first touch on button will be ignored.
	   */
	  public void setPressOnInit( boolean bool){
	    if(bool)
	      buttonLastPressed = -1;
	    else
	      buttonLastPressed = 0;
	  }// setPressOnInit
	  
	  public void setGameTimer( double timer_g ){
	    gameTimer = timer_g;
	  }// setGameTimer

	  public void setFadeOut(){
            if( !fadeEnable ) 
	      fadeAmount = 1;
	    fadeOut = true;
	    fadeIn = false;
	    doneFading = false;
	  }// setFadeOut
	  
	  public void setFadeIn(){
        if( !fadeEnable ) 
	      fadeAmount = 255;
	    fadeOut = false;
	    fadeIn = true;
	    doneFading = false;
	  }// setFadeOut
	  
	  public void setFadeColor(int newColor){
	    fadeColor = newColor;
	  }// setFadeColor
	  
	  public void setPosition(float x, float y){
	    xPos = x;
	    yPos = y;
	  }//setPosition
	  
	  public void setRotation(float newValue){
	    rotation = newValue;
	  }// setRotation
	  
          public void setScreenScale(float newScale){
            screenScale = newScale;
          }// setScreenScale
          
	  public void setHoldPress(boolean bool){
	    holdPress = bool;
	  }// setHoldPress

	  public void setHoldPress(boolean bool, int holdStyle){
	    holdPress = bool;
            if(bool)
              setHoldStyle(holdStyle);
	  }// setHoldPress
	  
	  public void setHoldIncrement(float newValue){
		  holdIncrement = newValue;
	  }// setHoldIncrement
	  
	  public void setHoldTrigger(float newValue){
		  holdTrigger = newValue;
	  }// setHoldTrigger
	  
	  public void setHoldStyle(int newValue){
	    holdStyle = newValue;
	  }// setHoldStyle
	  
          public void setActive(){
            STATE = ACTIVE;
          }
          
          public void setInactive(){
            STATE = INACTIVE;
          }
          
          public void disable(){
            STATE = DISABLED;
          }

	  
          public float getDiameter(){
            return diameter;
          }// getDiameter
          
          public String getButtonText(){
            return buttonText;
          }// getButtonText
          
	  public void fadeEnable(){
	    fadeEnable = true;
	  }// fadeEnable
	  
	  public void fadeDisable(){
	    fadeEnable = false;
	  }// fadeEnable   
	 
	  public boolean isButtonActive(){
	    if(STATE == ACTIVE)
	      return true;
	    else
	      return false;  
	  }// isActive
	  
	  public boolean isPressed(){
	    return pressed;
	  }// isPressed
	  
	  public boolean isLit(){
	    return lit;
	  }// isLit
	  
	  public boolean isDoneFading(){
	    return doneFading;
	  }// isDoneFading
}// MTButton class



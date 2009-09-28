

color[] selectedAirlineColors;

class SlidePane{
  float xPos, yPos;
  float paneWidth, paneHeight;
  boolean showing = false;
  ArrayList activeAirlines;
  ArrayList airlineButtons;
  int nButtons = 8;
  
  ArrayList colorPallet;
  
  int selectedColor = 0;
  
  // Color pallet
  color[] colors = {
      color(200,0,0),
      color(0,200,0),
      color(0,0,200),
  };

  // Coded for Vertical slide
  SlidePane(float x, float y, float w, float h){
    xPos = x;
    yPos = y;
    paneWidth = w;
    paneHeight = h;
    
    airlineButtons = new ArrayList();
    colorPallet = new ArrayList();
    activeAirlines = new ArrayList();
    selectedAirlineColors = new color[100];
    
    //activeAirlines.add( (String)FM.airlineList.get(0) );
    
    // Generate airline buttons based on airline list
    for( int i = 0; i < FM.airlineList.size(); i++ ){
      if( i >= nButtons )
        break;
      String name = (String)FM.airlineList.get(i);
      
      MTButton temp = new MTButton( parent, xPos - width/2 + 105 + 210*i , yPos - paneHeight/2 + 20, 200, 20 );
      temp.setButtonText(name);
      temp.setButtonTextColor(color(255,255,255));
      temp.setLitColor(color(5,75,75));
      temp.setDoubleSidedText(false);
      airlineButtons.add( temp );
    }// for
    
    // Generate color pallet
    for( int i = 0; i < 6; i++ ){
      MTButton temp = new MTButton( parent, xPos - width/2 + 105 + 20*i , yPos - paneHeight/2, 20, 20 );
      
      switch(i){
        case(0):
          temp.setIdleColor(colors[0]);
          temp.setLitColor(colors[0],color(255,255,255));
          break;
        case(1):
          temp.setIdleColor(colors[1]);
          temp.setLitColor(colors[1],color(255,255,255));
          break;
        case(2):
          temp.setIdleColor(colors[2]);
          temp.setLitColor(colors[2],color(255,255,255));
          break;
      }// switch
      
      colorPallet.add( temp );
      
    }// for
    
    if( !showing )
      yPos = height + paneHeight/2;
  }// CTOR
  
  float timer;
  float pressDelay = 0;
  void draw(){
    timer = millis();
    
    String activeAirline = (String)FM.airlineList.get(FM.selectedAirline);
    for( int i = 0; i < airlineButtons.size(); i++ ){
      if( i >= nButtons )
        break;
      MTButton temp = ((MTButton)airlineButtons.get(i));
      if( activeAirlines.contains( temp.getButtonText() ) )
        temp.setLit(true);
      else
        temp.setLit(false);
        
      if(mousePressed && millis() >= pressDelay){
        println("activeAirlines "+activeAirlines);
        
        // If button is unselected - add to active list
        if( temp.isButtonHit(mouseX,mouseY) && !temp.isLit() ){
          pressDelay = millis() + 100;
          activeAirlines.add( temp.getButtonText() );
          FM.setCurrentAirlines( activeAirlines );
          temp.setLitColor(colors[selectedColor]);
          selectedAirlineColors[activeAirlines.size()-1] = colors[selectedColor];
        // If button is selected - remove from active list
        }else if( temp.isButtonHit(mouseX,mouseY) ){
          pressDelay = millis() + 100;
          for( int j = 0; j < activeAirlines.size(); j++ ){
            if( ((String)activeAirlines.get(j)).equals( temp.getButtonText() ) ){
              activeAirlines.remove(j);
              break;
            }// if
          }// for
        }// if-else
          
      }// if mousePressed
    }// for
    
    
    for( int i = 0; i < colorPallet.size(); i++ ){
      MTButton temp = ((MTButton)colorPallet.get(i));
      if( selectedColor == i ){
        temp.setLit(true);
        
      } else
        temp.setLit(false);
      
      if(mousePressed){
        if( temp.isButtonHit(mouseX,mouseY) ){
          selectedColor = i;
        }
      }// if mousePressed
    }// for
    
    // Sliding animation
    if( showing ){
      if( yPos > height - paneHeight/2 )
        yPos -= 10;
      airlineSelector_button.setButtonText("<");
    }// if showing
    else {
      if( yPos < height + paneHeight/2 )
        yPos += 10;
      airlineSelector_button.setButtonText(">");
    }// else 
    
    // Display pane 
    if( yPos < height + paneHeight/2 ){
      displayPaneContents();
    }
  }// draw
  
  void displayPaneContents(){
    rectMode(CENTER);
        
    // Background box
    fill( 110,110,110, 200 );
    noStroke();
    rect( xPos, yPos, paneWidth, paneHeight );
    
    // Airline buttons
    for( int i = 0; i < airlineButtons.size(); i++ ){
      if( i >= nButtons )
        break;
      ((MTButton)airlineButtons.get(i)).setPosition(xPos - width/2 + 105 + 210*i , yPos - paneHeight/2 + 35);
      ((MTButton)airlineButtons.get(i)).process();
    }// for
    
    // Color selector
    for( int i = 0; i < colorPallet.size(); i++ ){
      ((MTButton)colorPallet.get(i)).setPosition(xPos - width/2 + 15 + 25*i , yPos - paneHeight/2 + 10);
      ((MTButton)colorPallet.get(i)).process();
    }// for
    
    rectMode(CORNER);
  }// displayPaneContents
  
  void togglePane(){
    showing = !showing;
  }// togglePane
  
}// class SlidePane

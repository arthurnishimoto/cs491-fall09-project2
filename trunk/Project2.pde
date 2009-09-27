import processing.opengl.*;
import javax.media.opengl.*;
import javax.media.opengl.glu.*;
import com.sun.opengl.util.*;
import java.nio.*;

//
// This is a test of the interactive Modest Maps library for Processing
// the modestmaps.jar in the code folder of this sketch might not be 
// entirely up to date - you have been warned!
//

/*
Keyboard Commands
1 - Road map
2 - Aerial map
3 - Hybird

[ - Decrement min date
] - increment min date

; - Decrement max date
' - increment max date

, - Previous airline
. - next airline

r - toggle render mode

*/

// this is the only bit that's needed to show a map:
InteractiveMap map;
InteractiveMap old; // Used to maintain old position when switching provider

// buttons take x,y and width,height:
ZoomButton out = new ZoomButton(5,5,14,14,false);
ZoomButton in = new ZoomButton(22,5,14,14,true);
PanButton up = new PanButton(14,25,14,14,UP);
PanButton down = new PanButton(14,57,14,14,DOWN);
PanButton left = new PanButton(5,41,14,14,LEFT);
PanButton right = new PanButton(22,41,14,14,RIGHT);

// all the buttons in one place, for looping:
Button[] buttons = { 
  in, out, up, down, left, right };

PFont font;

boolean gui = true;

FlightManager FM;

final static int ROAD = 0;
final static int AERIAL = 1;
final static int HYBRID = 2;
int MAP_STATE = HYBRID;

float updated;
boolean firstTimeIn, loaded;

PieChart loadingChart;
int currentFile = 0;
int maxFiles;

boolean processingRender = true;

void setup() {
  size(screen.width, screen.height,OPENGL);
  smooth();
  
  
  
  loaded = false;
  Runnable loader = new Runnable( ) {
    public void run( ) { FM = new FlightManager(); }
  };
  Thread thread = new Thread( loader );
  thread.start( );
  
  
  //flightManager.getAirlines();
  // create a new map, optionally specify a provider
  switch(MAP_STATE){
    case(ROAD):
      map = new InteractiveMap(this, new Microsoft.RoadProvider());
      break;
    case(AERIAL):
      map = new InteractiveMap(this, new Microsoft.AerialProvider());
      break;
    case(HYBRID):
      map = new InteractiveMap(this, new Microsoft.HybridProvider());
      break;
  }
  // others would be "new Microsoft.HybridProvider()" or "new Microsoft.AerialProvider()"
  // the Google ones get blocked after a few hundred tiles
  // the Yahoo ones look terrible because they're not 256px squares :)

  // set the initial location and zoom level to London:
  //  map.setCenterZoom(new Location(51.500, -0.126), 11);
  // zoom 0 is the whole world, 19 is street level
  // (try some out, or use getlatlon.com to search for more)

  // set a default font for labels
  font = createFont("Helvetica", 12);
  
  // enable the mouse wheel, for zooming
  addMouseWheelListener(new java.awt.event.MouseWheelListener() { 
    public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
      mouseWheel(evt.getWheelRotation());
    }
  }
  ); 
  
  updated = millis();
  firstTimeIn = true;
  
  loadingChart = new PieChart(width/2, height/2, 50);
  
}// setup

void switchToHybridMap(){
  old = map;
  map = new InteractiveMap(this, new Microsoft.HybridProvider());
  MAP_STATE = HYBRID;
    
  // Set position of new map to old map's last position
  map.tx = old.tx;
  map.ty = old.ty;
  map.sc = old.sc;
}// switchToHybridMap

void switchToAerialMap(){
  old = map;
  map = new InteractiveMap(this, new Microsoft.AerialProvider());
  MAP_STATE = AERIAL;
    
  // Set position of new map to old map's last position
  map.tx = old.tx;
  map.ty = old.ty;
  map.sc = old.sc;
}// switchToAerialMap

void switchToRoadMap(){
  old = map;
  map = new InteractiveMap(this, new Microsoft.RoadProvider());
  MAP_STATE = ROAD;
  
  // Set position of new map to old map's last position
  map.tx = old.tx;
  map.ty = old.ty;
  map.sc = old.sc;
}// switchToRoadMap

void draw() {
  background(0);

  // draw the map:
  map.draw();
  // (that's it! really... everything else is interactions now)
  
  if(!loaded){
    loadingChart.setValue_1( "", currentFile, color(0,0,200) ); // Unused
    loadingChart.display();
  }
  
  smooth();

  // draw all the buttons and check for mouse-over
  boolean hand = false;
  if (gui) {
    for (int i = 0; i < buttons.length; i++) {
      buttons[i].draw();
      hand = hand || buttons[i].mouseOver();
    }
  }

  // if we're over a button, use the finger pointer
  // otherwise use the cross
  // (I wish Java had the open/closed hand for "move" cursors)
  cursor(hand ? HAND : CROSS);

  // see if the arrow keys or +/- keys are pressed:
  // (also check space and z, to reset or round zoom levels)
  if (keyPressed) {
    if (key == CODED) {
      if (keyCode == LEFT) {
        map.tx += 5.0/map.sc;
      }
      else if (keyCode == RIGHT) {
        map.tx -= 5.0/map.sc;
      }
      else if (keyCode == UP) {
        map.ty += 5.0/map.sc;
      }
      else if (keyCode == DOWN) {
        map.ty -= 5.0/map.sc;
      }
    }  
    else if (key == '+' || key == '=') {
      map.sc *= 1.05;
    }
    else if (key == '_' || key == '-' && map.sc > 2) {
      map.sc *= 1.0/1.05;
    }
  }

  if (gui) {
    textFont(font, 12);

    // grab the lat/lon location under the mouse point:
    Location location = map.pointLocation(mouseX, mouseY);

    // draw the mouse location, bottom left:
    fill(0);
    noStroke();
    rect(5, height-5-g.textSize, textWidth("mouse: " + location), g.textSize+textDescent());
    fill(255,255,0);
    textAlign(LEFT, BOTTOM);
    text("mouse: " + location, 5, height-5);

    // grab the center
    location = map.pointLocation(width/2, height/2);

    // draw the center location, bottom right:
    fill(0);
    noStroke();
    float rw = textWidth("map: " + location);
    rect(width-5-rw, height-5-g.textSize, rw, g.textSize+textDescent());
    fill(255,255,0);
    textAlign(RIGHT, BOTTOM);
    text("map: " + location, width-5, height-5);
    
    if( loaded ){
    fill(0);
    noStroke();
    rw = textWidth("Airline: " + FM.getCurrentAirlineName());
    rect(0+50, 0+20-g.textSize, rw, g.textSize+textDescent());
    fill(255,255,0);
    textAlign(LEFT, BOTTOM);
    text("Airline: " + FM.getCurrentAirlineName(), 50, 20);
    
    fill(0);
    noStroke();
    rw = textWidth("From: " + FM.dateList.get(FM.minDate));
    rect(0+50, 0+30-g.textSize, rw, g.textSize+textDescent());
    fill(255,255,0);
    textAlign(LEFT, BOTTOM);
    text("From: " + FM.dateList.get(FM.minDate), 50, 30);
    
    fill(0);
    noStroke();
    rw = textWidth("To: " + FM.dateList.get(FM.maxDate));
    rect(0+50, 0+40-g.textSize, rw, g.textSize+textDescent());
    fill(255,255,0);
    textAlign(LEFT, BOTTOM);
    text("To: " + FM.dateList.get(FM.maxDate), 50, 40);
    }
    
    /*
    location = new Location(51.500, -0.126);
    Point2f p = map.locationPoint(location);

    fill(0,255,128);
    stroke(255,255,0);
    ellipse(p.x, p.y, 10, 10); 
    */
  }
  //println((float)map.sc);
  //println((float)map.tx + " " + (float)map.ty);
  //println();
  
  if(loaded)
  if(millis() - updated>=1000){
   
    
    if(firstTimeIn){
      FM.fillBuffer();
      firstTimeIn = false;
    }
    
    if( processingRender )
      FM.drawFlightPath();
    else
      FM.drawBuffer();
    
    
  }
  
}// draw

void mousePressed(){
  if( mouseButton == CENTER )
  println("Mouse at ["+(map.pointLocation(mouseX, mouseY))+"]");
}

void keyReleased() {

  if (key == 'g' || key == 'G') {
    gui = !gui;
  }
  else if (key == 's' || key == 'S') {
    save("modest-maps-app.png");
  }
  else if (key == ' ') {
    map.sc = 2.0;
    map.tx = -128;
    map.ty = -128; 
  }
  
  if(loaded){
  if (key == '1') {
    if( MAP_STATE != ROAD )
      switchToRoadMap();
  }
  else if (key == '2') {
    if( MAP_STATE != AERIAL )
      switchToAerialMap();
  }
  else if (key == '3') {
    if( MAP_STATE != HYBRID )
      switchToHybridMap();
  }
  else if (key == '[') {
    if( FM.minDate > 0 && FM.maxDate <= FM.dateList.size() - 1 && FM.minDate < FM.maxDate)
      FM.minDate--;
    updated = millis();
    firstTimeIn = true;
  }
  else if (key == ']') {
    if( FM.minDate >= 0 && FM.maxDate <= FM.dateList.size() - 1 && FM.minDate < FM.maxDate)
      FM.minDate++;
    updated = millis();
    firstTimeIn = true;
  }
  else if (key == ';') {
    if( FM.minDate >= 0 && FM.maxDate <= FM.dateList.size() - 1 && FM.minDate < FM.maxDate)
      FM.maxDate--;
    updated = millis();
    firstTimeIn = true;
  }
  else if (key == '\'') {
    if( FM.minDate >= 0 && FM.maxDate <= FM.dateList.size() - 1 && FM.minDate < FM.maxDate)
      FM.maxDate++;
    updated = millis();
    firstTimeIn = true;
  }
  
  }// if loaded
  
  if (key == 'z' || key == 'Z') {
    
     FM.fillBuffer();
    //updated = millis();
  }
  if (key == ' ') {
    map.sc = 2.0;
    map.tx = -128;
    map.ty = -128; 
    updated = millis();
    firstTimeIn = true;
  }
  
  if(key == '.' ){
  
    if(FM.selectedAirline>=0 && FM.selectedAirline<FM.totalAirline){
      FM.selectedAirline++;
    firstTimeIn = true;
    updated = millis();
    }

  }
  if(key == ',' ){
  
    if(FM.selectedAirline>=1 && FM.selectedAirline<FM.totalAirline){
      FM.selectedAirline--;
    firstTimeIn = true;
    updated = millis();
    }

  }  
  
  if( key == 'r' || key == 'R' )
    processingRender = !processingRender;
}// keyReleased


// see if we're over any buttons, otherwise tell the map to drag
void mouseDragged() {
  boolean hand = false;
  if (gui) {
    for (int i = 0; i < buttons.length; i++) {
      hand = hand || buttons[i].mouseOver();
      if (hand) break;
    }
  }
  if (!hand) {
    map.mouseDragged(); 
  }
  firstTimeIn = true;
  updated = millis();
}

// zoom in or out:
void mouseWheel(int delta) {
  if (delta > 0) {
    map.sc *= 1.05;
  }
  else if (delta < 0) {
    map.sc *= 1.0/1.05; 
  }
  firstTimeIn = true;
  updated = millis();
}

// see if we're over any buttons, and respond accordingly:
void mouseClicked() {
  if (in.mouseOver()) {
    map.zoomIn();
  }
  else if (out.mouseOver()) {
    map.zoomOut();
  }
  else if (up.mouseOver()) {
    map.panUp();
  }
  else if (down.mouseOver()) {
    map.panDown();
  }
  else if (left.mouseOver()) {
    map.panLeft();
  }
  else if (right.mouseOver()) {
    map.panRight();
  }
}

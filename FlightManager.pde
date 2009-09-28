import java.util.Hashtable;

/*
Day of week index for minDate/maxDate
6/05 F = 0
6/06 S = 284
6/07 S = 570
6/08 M = 854
6/09 T = 1139
6/10 W = 1417
6/11 T = 1703
6/12 F = 1988
*/
PGraphics buffer;
PImage img;

class FlightManager{
  static final int LATITUDE = 0;
  static final int LONGITUDE = 1;
  static final int BEARING = 2;
  static final int DEPARTING = 3;
  
  Pattern  p, p2;
  
  Hashtable FLIGHTS;

  float startTime = millis() / 1000;
  
  //testing using buffers
  FloatBuffer vbuffer;
  FloatBuffer cbuffer;
  int numPoints;
  
  ArrayList airlineList;
  int selectedAirline = 0;
  int totalAirline = 0;
  ArrayList selectedAirlines;
  
  ArrayList dateList;
  int minDate = 0;
  int maxDate = 0;
  int totalDays;
  
  color departingColor = color( 0, 255, 0 );
  color arrivingColor = color( 255, 0, 0 );
  int transparency = 75;
  
  ArrayList activeCoordinates; // List of selected coordinates
  
  FlightManager(){
    buffer = createGraphics(width,height, OPENGL);
    
    FLIGHTS = new Hashtable();
    
    airlineList = new ArrayList();
    dateList = new ArrayList();
    selectedAirlines = new ArrayList();
    
    ArrayList fileNames = new ArrayList();
    activeCoordinates = new ArrayList();
    
    // Regular expression usd to parse file
    p = Pattern.compile("<Flight\\sId=\"([\\d]+)\"\\sFlight=\"([\\w\\d\\s\\w\\d]+)\"\\sAirline=\"(.*)\"\\sLatitude=\"(\\-?\\d+\\.\\d+)\"\\sLongitude=\"(\\-?\\d+\\.\\d+)\"\\sBearing=\"(\\d+)\"\\sIsDep=\"(\\d+)\"\\s");
    
    String datasetDirectory = sketchPath("")+"airport";
    println(datasetDirectory);
    
    // Get the list of files in the directory 
    File dir = new File(datasetDirectory);
    String[] dirList = dir.list();
    if( dirList != null ){
      for( int i = 0; i < dirList.length; i++ ){
        
        // Ignore non-data files (Files should be in ORD.[DATE][TIME] format)
        if( dirList[i].contains("ORD") ){
          fileNames.add(dirList[i]);
          dateList.add( dirList[i].substring(4,dirList[i].length()-4 ) );
        }
      }// for
    }// if
    //saveStrings("dateList", dirList);
    maxFiles = fileNames.size();
    // For each log files in directory, read and parse
    for( int i = 0; i < fileNames.size(); i++ ){
      currentFile = i+1;
      readLog( (String)fileNames.get(i), datasetDirectory+"\\"+fileNames.get(i), (String)dateList.get(i) );
      println("Read file "+currentFile+"/"+maxFiles+" for date: "+dateList.get(i));
    }
    maxDate = fileNames.size() - 1;
    println("Done loading files. Time elapsed: "+(( millis() - startTime ) / 1000)+" seconds.");
    fillAirlineList();
    
    totalDays = maxDate;
  }// CTOR
  
  void fillAirlineList(){
  
    Set _airlineList;
    _airlineList = new HashSet();
    
    PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
    GL gl = pgl.beginGL();
   
    println("Number of flights: "+ FLIGHTS.size());
    Enumeration e = FLIGHTS.elements();
    Flight temp;
    
    while( e.hasMoreElements() ){
      temp = (Flight)e.nextElement();
      _airlineList.add(temp.getAirline());
    }
   
    pgl.endGL();
    println("Number of airlines: "+ _airlineList.size());
    totalAirline = _airlineList.size();
    
    Iterator it = _airlineList.iterator();
    while(it.hasNext()){
      //println("Number of airlines: "+it.next() );
      airlineList.add(it.next());
    }
  }// fillAirlineList
  
  void readLog(String path, String dataLine, String logDate){
    String lines[] = loadStrings(dataLine);
    int nCoordinates = 0;
    
    // Log date format: MM-DD-YYYY-HH-MM ( Month, day, year, hour, min )
    //int dayNumber = Integer.valueOf( logDate.substring(3,5) );
    //println( dayNumber );
    
    // Read the dataline
    for(int i = 0 ; i < lines.length ; i++){
      
      String[] tempS = splitTokens(lines[i], "/>");
      
      // Parse the data log
      for(int j = 0 ; j < tempS.length ; j++){
        Matcher m = p.matcher(tempS[j]);
        boolean b = m.matches();
        if(b){
          //println(m.group(1) + " " + m.group(2) + " " +m.group(3) + " " +float(m.group(4)) + " " +float(m.group(5)) + " " +int(m.group(6)) + " " +int(m.group(7)));
          float[] position = { float(m.group(4)), float(m.group(5)), float(m.group(6)), float(m.group(7)) };
            // [0] Latitude
            // [1] Longitude
            // [2] Bearing
            // [3] Departing
          int flightID = Integer.valueOf( m.group(1) );
          //println(flightID);
          // Adds flight to hashtable
          if( !FLIGHTS.containsKey( flightID ) ){ // If not a duplicate flight ID
            FLIGHTS.put( flightID, new Flight(flightID,currentFile,logDate,m.group(2),m.group(3),position,int(m.group(7)) ) );
            nCoordinates++;
          } else { // Append new position to existing flight
            Flight existing = (Flight)FLIGHTS.get( flightID );
            existing.addPosition( currentFile, logDate, position );
            nCoordinates++;
          } // else
          //println(m.group(1) + " " + m.group(2) + " " +m.group(3) + " " +float(m.group(4)) + " " +float(m.group(5)) + " " +int(m.group(6)) + " " +int(m.group(7)));
          //coordList.add(new coords(m.group(1),m.group(2),m.group(3),float(m.group(4)),float(m.group(5)),int(m.group(6)),int(m.group(7))));
        }// if
      }// for

    }// for
    
    println(numPoints+" coordinates loaded");
    numPoints += nCoordinates;
  }// readLog
  
  String getCurrentAirlineName(){
    if( airlineList.isEmpty() )
      return "None Selected";
    else
      return (String)airlineList.get(selectedAirline);
  }// getCurrentAirlineName
  
  void fillBuffer(){
  
    //println(coordList.size() + " frameRate " + frameRate);
    
    
    PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
    GL gl = pgl.beginGL();
    vbuffer = BufferUtil.newFloatBuffer(numPoints * 2);
    cbuffer = BufferUtil.newFloatBuffer(numPoints * 3);   
    
    Enumeration e = FLIGHTS.elements();
    ArrayList tempCoords = activeCoordinates;
    //println("activeCoordinates size: "+activeCoordinates.size() );
      for( int i = 0; i < tempCoords.size(); i++ ){

        Coords c = (Coords)tempCoords.get(i); // Get coord from list
        Flight tempFlight = c.getFlight(); // Get the Flight coord belongs to
        Location l = c.getLocation();
        Point2f p = map.locationPoint( l );

        //Point2f p = map.locationPoint( new Location((float)pos[0], (float)pos[1]) );
        //println(tempCoords.id + " " + tempCoords.flight + " " + tempCoords.airline + " " + tempCoords.lat + " " + tempCoords.lon + " " + tempCoords.bearing + " " + tempCoords.isDep);
        //161668415 works
        for( int j = 0; j < selectedAirlines.size(); j++ ){
          MTButton airline = (MTButton)selectedAirlines.get(j);
          String airlineName = airline.getButtonText();
          color userColor = airline.lit_cl;
          
        if( airlineName.contains(tempFlight.getAirline()) ){
          vbuffer.put(p.x);
          vbuffer.put(p.y);
          
          if( !tempFlight.isDeparting() ){
            cbuffer.put(1.0);
            cbuffer.put(0.0);
            cbuffer.put(0.0);        
          }else{
            cbuffer.put(0.0);
            cbuffer.put(1.0);
            cbuffer.put(0.0);        
          }
  
          //println("tempCoords.flight");
        }// if airline
        }// for selected
      }// for tempCoords
    
    vbuffer.rewind();
    cbuffer.rewind();
   
    gl.glEnableClientState(GL.GL_VERTEX_ARRAY);
    gl.glVertexPointer(2, GL.GL_FLOAT, 0, vbuffer);
   
    gl.glEnableClientState(GL.GL_COLOR_ARRAY);
    gl.glColorPointer(3, GL.GL_FLOAT, 0, cbuffer);
   
    pgl.endGL();
  }// fillBuffer
  
  void drawBuffer(){
    
    PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;  // g may change
    GL gl = pgl.beginGL();  // always use the GL object returned by beginGL
   
    gl.glPushMatrix();
    /*gl.glTranslatef(width/2, height/2, 0);
    gl.glScalef(sc,sc,sc);
    gl.glRotatef(a, 0.0, 0.0, 1.0);
    gl.glTranslatef(-width/2, -height/2, 0);
    gl.glTranslatef(tx,ty, 0);
    */
    gl.glPointSize(2.0);
   
    //gl.glDrawArrays(GL.GL_LINE_STRIP, 0, numPoints);
    gl.glDrawArrays(GL.GL_POINTS, 0, numPoints);
    gl.glPopMatrix();
   
    pgl.endGL();
  }// drawBuffer
  
  void drawFlightPath(){
    Enumeration e = FLIGHTS.elements();
    boolean currentPos;
    
      ArrayList tempCoords = activeCoordinates;
      for( int i = 0; i < tempCoords.size(); i++ ){
        currentPos = false;
        
        Coords c = (Coords)tempCoords.get(i); // Get coord from list
        
        if( maxDate == c.getTimestampID() )
          currentPos = true;
          
        Flight tempFlight = c.getFlight(); // Get the Flight coord belongs to
        Location l = c.getLocation();
        Point2f p = map.locationPoint( l );

        //if(tempFlight.getAirline().equals(airlineList.get(selectedAirline))){
        
        for( int j = 0; j < selectedAirlines.size(); j++ ){
          MTButton airline = (MTButton)selectedAirlines.get(j);
          String airlineName = airline.getButtonText();
          color userColor = airline.lit_cl;
          
        if( airlineName.contains(tempFlight.getAirline()) ){
          
          pushMatrix();
          translate( p.x, p.y );
          rotate( radians(c.getBearing() - 90) );
          
          for( int k = 0; k < airlineButtons.size(); k++ )
          // Override colors determined by airline selector
          arrivingColor = userColor;
          departingColor = userColor;
          
          if( !tempFlight.isDeparting() ){
            if( currentPos ){
              stroke(arrivingColor); // Green = arriving 
              fill(arrivingColor);
            } else {
              stroke(arrivingColor, transparency); // Green = arriving 
              fill(arrivingColor, transparency);
            }
            line( 0, 0, 50, 0 );
            stroke(0,0,0);
            ellipse(0, 0, 10, 10);
          } else {
            if( currentPos ){
              stroke(departingColor); // Red = departing
              fill(departingColor);
            } else {
              stroke(departingColor, transparency); // Red = departing
              fill(departingColor, transparency);
            }
            
            line( 0, 0, 50, 0 );
            stroke(0,0,0);
            ellipse(0, 0, 10, 10);
          }
          popMatrix();
        }// if
        }//for selectedAirlines
      }// for tempCoords
        
  }// drawFlightPath
  
  void setDate( int newMinDate , int newMaxDate ){
    String minTimestamp = (String)dateList.get(newMinDate);
    String maxTimestamp = (String)dateList.get(newMaxDate);
    
    println("setDate called for timestamps '"+minTimestamp+"' through '"+maxTimestamp+"'.");
    minDate = newMinDate;
    maxDate = newMaxDate;
    
    activeCoordinates.clear();
    Enumeration e = FLIGHTS.elements();

    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeCoordinates.addAll( tempFlight.getCoords(minDate,maxDate) );

    }// while
    
  }// setDate
  
  void clearActiveCoordinates(){
    activeCoordinates.clear();
  }// clearActiveFlights
  
  void addDayOne(){
    Enumeration e = FLIGHTS.elements();

    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeCoordinates.addAll( tempFlight.getDayOne() );

    }// while
    //println("Day One - Total Coordinates: "+activeCoordinates.size());
  }// addDayOne
  
  void addDayTwo(){
    Enumeration e = FLIGHTS.elements();

    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeCoordinates.addAll( tempFlight.getDayTwo() );

    }// while
    //println("Day Two - Total Coordinates: "+activeCoordinates.size());
  }// addDayTwo
  
  void addDayThree(){
    Enumeration e = FLIGHTS.elements();

    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeCoordinates.addAll( tempFlight.getDayThree() );

    }// while
  }// addDayThree
  
  void addDayFour(){
    Enumeration e = FLIGHTS.elements();

    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeCoordinates.addAll( tempFlight.getDayFour() );

    }// while
  }// addDayFour
  
  void addDayFive(){
    Enumeration e = FLIGHTS.elements();

    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeCoordinates.addAll( tempFlight.getDayFive() );

    }// while
  }// addDayFive
  
  void addDaySix(){
    Enumeration e = FLIGHTS.elements();

    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeCoordinates.addAll( tempFlight.getDaySix() );

    }// while
  }// addDaySix
  
  void addDaySeven(){
    Enumeration e = FLIGHTS.elements();

    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeCoordinates.addAll( tempFlight.getDaySeven() );

    }// while
  }// addDaySeven
  
  void addDayEight(){
    Enumeration e = FLIGHTS.elements();

    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeCoordinates.addAll( tempFlight.getDayEight() );

    }// while
  }// addDayEight
    
  void setCurrentAirlines(ArrayList newList){
    selectedAirlines = newList;
  }// setCurrentAirline
  
}// FlightManager

class Flight{
  int flightID;
  String flightName, airline;
  boolean departing;
  
  int firstTimestamp, lastTimestamp;
  
  ArrayList flightPositions;
  // float[]:
  // [0] Latitude
  // [1] Longitude
  // [2] Bearing
  // [3] isDeparting

  Flight(int ID, int timestampID, String timestamp, String name, String airlineName, float[] pos, int isDep){
    flightID = ID;
    flightName = name;
    airline = airlineName;
    
    firstTimestamp = timestampID;
    lastTimestamp = timestampID;
    
    flightPositions = new ArrayList();
    addPosition(timestampID, timestamp, pos);
    
    switch(isDep){
      case(0):
        departing = false;
        break;
      case(1):
        departing = true;
        break;
    }//switch
  }// CTOR
  
  boolean isDeparting(){
    return departing;
  }// isDeparting
  
  boolean isFlightInTimeRange( int minVal, int maxVal ){
    if( firstTimestamp >= minVal || lastTimestamp <= maxVal )
      return true;
    else
      return false;
  }// isFlightInTimeRange
  
  void addPosition( int tsID, String timestamp, float[] pos ){
    flightPositions.add( new Coords( this, tsID, timestamp, new Location( pos[0], pos[1] ) , (int)pos[2] ) );
    
    if( firstTimestamp > tsID )
      firstTimestamp = tsID;
    if( lastTimestamp < tsID )
      lastTimestamp = tsID;
    //flightPositions.add( new Location( pos[0], pos[1] ) );
    //flightPositions.add( pos );
  }// addPosition
  
  void addPosition( Point2f pos ){
    flightPositions.add(pos);
  }// addPosition
  
  String toString(){
    String output = "\n";
    output += "Flight ID: "+flightID+"\n";
    output += "Flight   : "+flightName+"\n";
    output += "Path Coordinates\n";
    for( int i = 0; i < flightPositions.size(); i++ ){
      //float[] temp = (float[])flightPositions.get(i);
      //output += "["+temp[0]+","+temp[1]+"] "+temp[2]+"\n";
    }
    return output+"\n";
  }// toString
  
  ArrayList getFlightPath(){
    return flightPositions;
  }// getFlightpath
  
  ArrayList getCoords(int start, int end){
    ArrayList out = new ArrayList();
    
    for( int i = 0; i < flightPositions.size(); i++ ){
      Coords tempCoord = (Coords)flightPositions.get(i);
 
      if( tempCoord.getTimestampID() >= start && tempCoord.getTimestampID() <= end )
        out.add( flightPositions.get(i) );
    }
    return out;
    
  }// getFlightpath
  
  // Returns an arraylist of all coords in this flight on day 1
  ArrayList getDayOne(){ // 06-05-2009
    ArrayList output = new ArrayList();
    for( int i = 0; i < flightPositions.size(); i++ ){
      Coords tempCoord = (Coords)flightPositions.get(i);
      if( tempCoord.getDay() == 5 )
        output.add( tempCoord );
    }// for
    return output;
  }// getDay1

  ArrayList getDayTwo(){ // 06-06-2009
    ArrayList output = new ArrayList();
    for( int i = 0; i < flightPositions.size(); i++ ){
      Coords tempCoord = (Coords)flightPositions.get(i);
      if( tempCoord.getDay() == 6 )
        output.add( tempCoord );
    }// for
    return output;
  }// getDay2
  
  ArrayList getDayThree(){ // 06-07-2009
    ArrayList output = new ArrayList();
    for( int i = 0; i < flightPositions.size(); i++ ){
      Coords tempCoord = (Coords)flightPositions.get(i);
      if( tempCoord.getDay() == 7 )
        output.add( tempCoord );
    }// for
    return output;
  }// getDay3
  
  ArrayList getDayFour(){ // 06-08-2009
    ArrayList output = new ArrayList();
    for( int i = 0; i < flightPositions.size(); i++ ){
      Coords tempCoord = (Coords)flightPositions.get(i);
      if( tempCoord.getDay() == 8 )
        output.add( tempCoord );
    }// for
    return output;
  }// getDay4
  
  ArrayList getDayFive(){ // 06-09-2009
    ArrayList output = new ArrayList();
    for( int i = 0; i < flightPositions.size(); i++ ){
      Coords tempCoord = (Coords)flightPositions.get(i);
      if( tempCoord.getDay() == 9 )
        output.add( tempCoord );
    }// for
    return output;
  }// getDay5
  
  ArrayList getDaySix(){ // 06-10-2009
    ArrayList output = new ArrayList();
    for( int i = 0; i < flightPositions.size(); i++ ){
      Coords tempCoord = (Coords)flightPositions.get(i);
      if( tempCoord.getDay() == 10 )
        output.add( tempCoord );
    }// for
    return output;
  }// getDay6
  
  ArrayList getDaySeven(){ // 06-11-2009
    ArrayList output = new ArrayList();
    for( int i = 0; i < flightPositions.size(); i++ ){
      Coords tempCoord = (Coords)flightPositions.get(i);
      if( tempCoord.getDay() == 11 )
        output.add( tempCoord );
    }// for
    return output;
  }// getDay7
  
  ArrayList getDayEight(){ // 06-12-2009
    ArrayList output = new ArrayList();
    for( int i = 0; i < flightPositions.size(); i++ ){
      Coords tempCoord = (Coords)flightPositions.get(i);
      if( tempCoord.getDay() == 12 )
        output.add( tempCoord );
    }// for
    return output;
  }// getDay8
  
  String getAirline(){
    if( airline != null )
      return airline;
    else
      return "NULL AIRLINE NAME";
  }// getAirline
  
  float[] getEndPositionNotOHare(){
    if( departing ) // Get destination
      return (float[])flightPositions.get(flightPositions.size());
    else // Get source
      return (float[])flightPositions.get(0);
  }// getEndPositionNotOHare

}// Flight

class Coords{
  Location location;
  int bearing;
  Flight p;
  String timestamp;
  int MONTH, DAY, YEAR, HOUR, MINUTE;
  int timestampID;
  
  Coords( Flight parent, int tsID, String time, Location l, int b ){
    location = l;
    bearing = b;
    p = parent;
    timestamp = time;
    timestampID = tsID;
    
    //MM-DD-YYYY-HH-MM
    
    MONTH = Integer.valueOf( timestamp.substring(0,2) );
    DAY = Integer.valueOf( timestamp.substring(3,5) );
    YEAR = Integer.valueOf( timestamp.substring(6,10) );
    HOUR = Integer.valueOf( timestamp.substring(11,13) );
    MINUTE = Integer.valueOf( timestamp.substring(14,16) );
  }// CTOR
  
  Location getLocation(){
    return location;
  }// getLocation
  
  int getBearing(){
     return bearing;
  }// getBearing
  
  Flight getFlight(){
    return p;
  }// getFlight
  
  int getDay(){
    return DAY;
  }// getDay
  
  String getTimestamp(){
    return timestamp;
  }// getTimestamp
  
  int getTimestampID(){
    return timestampID;
  }// getTimestampID
}// coords

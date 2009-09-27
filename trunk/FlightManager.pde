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
  
  ArrayList dateList;
  int minDate = 0;
  int maxDate = 0;
  int totalDays;
  
  color departingColor = color( 0, 255, 0 );
  color arrivingColor = color( 255, 0, 0 );
  int transparency = 75;
  
  ArrayList activeFlights; // List of selected flights
  
  FlightManager(){
    FLIGHTS = new Hashtable();
    
    airlineList = new ArrayList();
    dateList = new ArrayList();
    
    ArrayList fileNames = new ArrayList();
    activeFlights = new ArrayList();
    
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
      readLog( (String)fileNames.get(i), datasetDirectory+"\\"+fileNames.get(i) );
      println("Read file "+currentFile+"/"+maxFiles);
    }
    maxDate = fileNames.size() - 1;
    println("Done loading files. Time elapsed: "+(( millis() - startTime ) / 1000)+" seconds.");
    fillAirlineList();
    
    totalDays = maxDate;
    loaded = true;
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
  
  void readLog(String path, String dataLine){
    String lines[] = loadStrings(dataLine);
    
    // Read the path line (containing time and date) Format: 'ORD.06-07-2009-06-22.log'
  

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
          if( !FLIGHTS.containsKey( flightID ) ) // If not a duplicate flight ID
            FLIGHTS.put( flightID, new Flight(flightID,m.group(2),m.group(3),position,int(m.group(7)) ) );
          else { // Append new position to existing flight
            Flight existing = (Flight)FLIGHTS.get( flightID );
            existing.addPosition( position );
          } // else
          //println(m.group(1) + " " + m.group(2) + " " +m.group(3) + " " +float(m.group(4)) + " " +float(m.group(5)) + " " +int(m.group(6)) + " " +int(m.group(7)));
          //coordList.add(new coords(m.group(1),m.group(2),m.group(3),float(m.group(4)),float(m.group(5)),int(m.group(6)),int(m.group(7))));
        }// if
      }// for

    }// for

    numPoints = FLIGHTS.size();
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
    
    while( e.hasMoreElements() ){
     
      Flight tempFlight = (Flight)e.nextElement();
      ArrayList tempCoords = tempFlight.getFlightPath(minDate,maxDate);
      
      for( int i = 0; i < tempCoords.size(); i++ ){
        //float[] pos = (float[])tempCoords.get(i);
        Coords c = (Coords)tempCoords.get(i);
        Location l = c.getLocation();
        Point2f p = map.locationPoint( l );
        //Point2f p = map.locationPoint( new Location((float)pos[0], (float)pos[1]) );
        //println(tempCoords.id + " " + tempCoords.flight + " " + tempCoords.airline + " " + tempCoords.lat + " " + tempCoords.lon + " " + tempCoords.bearing + " " + tempCoords.isDep);
        //161668415 works
        if(tempFlight.getAirline().equals(airlineList.get(selectedAirline))){
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
        }
      }// for tempCoords
      
    }// while FLIGHTs
    
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
    println(minDate+" "+maxDate);
    while( e.hasMoreElements() ){
     
      Flight tempFlight = (Flight)e.nextElement();
      ArrayList tempCoords = tempFlight.getFlightPath(minDate,maxDate);
      
      for( int i = 0; i < tempCoords.size(); i++ ){
        Coords c = (Coords)tempCoords.get(i);
        Location l = c.getLocation();
        Point2f p = map.locationPoint( l );

        if(tempFlight.getAirline().equals(airlineList.get(selectedAirline))){
          pushMatrix();
          translate( p.x, p.y );
          rotate( radians(c.getBearing() - 90) );
            
          if( !tempFlight.isDeparting() ){
            if( i == tempCoords.size() - 1 ){
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
            if( i == 0 ){
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
      }// for tempCoords
      
    }// while FLIGHTs
    
  }// drawFlightPath
  
  void setDate(int minD, int maxD){
    if( minD >= 0 && maxD <= dateList.size() - 1 && minD < maxD){
      minDate = minD;
      maxDate = maxD;
    }
  }// setDate
  
  ArrayList getFlights(){
    return activeFlights;
  }// getFlights
  
  void clearActiveFlights(){
    activeFlights.clear();
  }// clearActiveFlights
  
  void addDayOne(){
    Enumeration e = FLIGHTS.elements();
    
    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeFlights.addAll( tempFlight.getDayOne() );
      
    }// while
    
  }// addDayOne
  
  void addDayTwo(){
    Enumeration e = FLIGHTS.elements();
    
    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeFlights.addAll( tempFlight.getDayOne() );
      
    }// while
  }// addDayX
  
  void addDayThree(){
    Enumeration e = FLIGHTS.elements();
    
    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeFlights.addAll( tempFlight.getDayThree() );
      
    }// while
  }// addDayX
  
  void addDayFour(){
    Enumeration e = FLIGHTS.elements();
    
    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeFlights.addAll( tempFlight.getDayFour() );
      
    }// while
  }// addDayX
  
  void addDayFive(){
    Enumeration e = FLIGHTS.elements();
    
    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeFlights.addAll( tempFlight.getDayFive() );
      
    }// while
  }// addDayX
  
  void addDaySix(){
    Enumeration e = FLIGHTS.elements();
    
    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeFlights.addAll( tempFlight.getDaySix() );
      
    }// while
  }// addDayX
  
  void addDaySeven(){
    Enumeration e = FLIGHTS.elements();
    
    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeFlights.addAll( tempFlight.getDaySeven() );
      
    }// while
  }// addDayX
  
  void addDayEight(){
    Enumeration e = FLIGHTS.elements();
    
    while( e.hasMoreElements() ){
      Flight tempFlight = (Flight)e.nextElement();
      activeFlights.addAll( tempFlight.getDayEight() );
      
    }// while
  }// addDayX
}// FlightManager

class Flight{
  int flightID;
  String flightName, airline;
  boolean departing;
  
  ArrayList flightPositions;
  // float[]:
  // [0] Latitude
  // [1] Longitude
  // [2] Bearing
  // [3] isDeparting

  Flight(int ID, String name, String airlineName, float[] pos, int isDep){
    flightID = ID;
    flightName = name;
    airline = airlineName;
    
    flightPositions = new ArrayList();
    addPosition(pos);
    
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
  
  void addPosition( float[] pos ){
    flightPositions.add( new Coords( new Location( pos[0], pos[1] ) , (int)pos[2] ) );
    
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
  
  ArrayList getFlightPath(int start, int end){
    if( end >= flightPositions.size() )
      end = flightPositions.size() - 1;
    if( start >= flightPositions.size() )
      start = flightPositions.size() - 1;
      
    ArrayList out = new ArrayList();
    for( int i = start; i < end; i++ ){
      out.add( flightPositions.get(i) );
    }
    return out;
  }// getFlightpath
  
  ArrayList getDayOne(){
    return getFlightPath(0, 284);
  }// getDay1
  
  ArrayList getDayTwo(){
    return getFlightPath(284, 570);
  }// getDay2
  
  ArrayList getDayThree(){
    return getFlightPath(570,854);
  }// getDay3
  
  ArrayList getDayFour(){
    return getFlightPath(854,1139);
  }// getDay4
  
  ArrayList getDayFive(){
    return getFlightPath(1139,1417);
  }// getDay5
  
  ArrayList getDaySix(){
    return getFlightPath(1417,1703);
  }// getDay6
  
  ArrayList getDaySeven(){
    return getFlightPath(1703,1988);
  }// getDay7
  
  ArrayList getDayEight(){
    return getFlightPath(1988,flightPositions.size());
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
  
  Coords( Location l, int b ){
    location = l;
    bearing = b;
  }// CTOR
  
  Location getLocation(){
    return location;
  }// getLocation
  
  int getBearing(){
     return bearing;
  }// getBearing
}// coords

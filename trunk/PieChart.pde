/**
 * ---------------------------------------------
 * PieChart.pde
 * Description: Pie Chart implementation. Supports up to 8 values.
 *
 * Class: CS 488 - Fall 2009
 * System: Processing 1.0.1, Windows XP SP2 / Windows Vista
 * Author: Arthur Nishimoto
 * Version: 0.1
 *
 * Version Notes:
 * 9/8/09    - Initial version
 * ---------------------------------------------
 */
 
class PieChart{
  float xPos, yPos, radius;
  float legend_xPos, legend_yPos;
  float legend_static_xPos, legend_static_yPos;
  
  color legend_font_color = color(0,200,200);
  int legend_font_size = 16;
  PFont legend_font = font;
  
  int legend_height = 0;
  boolean displayLegendValues = true;
  float legend_value_offset = 120;
  boolean show_legend = true;
  
  String chart_label = "Loading";
  String label_1 = "Label 1";
  String label_2 = "Label 2";
  String label_3 = "Label 3";
  String label_4 = "Label 4";
  String label_5 = "Label 5";
  String label_6 = "Label 6";
  String label_7 = "Label 7";
  String label_8 = "Label 8";
  
  float value_1 = 00;
  float value_2 = 20;
  float value_3 = 30;
  float value_4 = 15;
  float value_5 = 11;
  float value_6 = 4;
  float value_7 = 32;
  float value_8 = 91; 
  float value_sum = value_1 + value_2 + value_3 + value_4 + value_5 + value_6 + value_7 + value_8;
  
  color color_1 = color( 255, 0, 0 ); 
  
  int SECTORS = 90; // Max 90
  float INITIAL_ANGLE_OFFSET = -90;
    
  PieChart(float x, float y, float r){
    xPos = x;
    yPos = y;
    radius = r;
    legend_xPos = xPos + radius + 10;
    legend_yPos = yPos - radius/2 + 10;
    legend_static_xPos = legend_xPos;
    legend_static_yPos = legend_yPos;
  }// CTOR
  
  void display(){
    value_sum = maxFiles;
    legend_xPos = xPos + radius + 10;
    legend_yPos = yPos - radius/2 + 10;
    
    fill(0,0,0);
    noStroke();
    rect( xPos - 30, yPos - radius - legend_font_size*2, 60, 20 );
    
    fill(legend_font_color);
    textFont(legend_font,legend_font_size);
    textAlign(CENTER);
    text( chart_label, xPos, yPos - radius - legend_font_size);
    textAlign(LEFT);
    
    for( int i = 0; i < SECTORS; i++ ){
      float angle = i*(360/SECTORS);
      beginShape();
            
      if( angle/360 < value_1/value_sum )
        fill(color_1, 200);
      else
        fill(0, 0, 0, 100);
        
      noStroke();
      
      // Creates a triangle
      vertex( xPos, yPos );
      vertex( xPos+radius*cos( radians(angle + INITIAL_ANGLE_OFFSET) ), yPos+radius*sin( radians(angle + INITIAL_ANGLE_OFFSET) ) );
      vertex( xPos+radius*cos( radians((i+1)*(360/SECTORS) + INITIAL_ANGLE_OFFSET) ), yPos+radius*sin( radians((i+1)*(360/SECTORS) + INITIAL_ANGLE_OFFSET) ) );
      endShape(CLOSE);    
    }// for
  }// display
   
  void setValue_1( String label, float value, color new_color ){
    label_1 = label;
    value_1 = value;
    color_1 = new_color;
  }// setValue_1

}// class PieChart

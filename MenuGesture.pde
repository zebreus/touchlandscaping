// The distance, when the menu is fully opened. (mm) //<>//
float inner_distance = 30;
// Minimal start distance
float minimum_distance = 50;
// Maximum start distance
float maximum_distance = 150;
// The rotation threshold, before this gesture is discarded
float angle_threshold = 30.0;
// If the distance decreased more than this, the gesture is detected. (mm)
float distance_threshold = 10;
// A bit of travel apart should be allowed
float reverse_travle_threshold = 5;
// Whether the menu should rotate
boolean rotate_menu = true;
// Whether to move the menu after match
boolean move_menu = false;
// Whether to open the menu if one finger is removed, while the menu is still opening
// boolean open_menu
// Whether to draw a selection ark
boolean draw_arc = true;
// Menu center deadzone ( in mm )
float menu_center_deadzone = 15;
// Menu outside deadzone ( in mm )
float menu_border_deadzone = 60;

public class MenuGesture extends Gesture {
  //The new point has to be older than minimumTime and younger than maximum time
  TuioTime minAge = new TuioTime(100);
  TuioTime maxAge = new TuioTime(1000);
  float initialDistance;
  float initialAngle;
  float lastDistance;
  float detectDistance;
  Tool selectedTool;
  boolean initialized = false;
  // Store how much travel apart has happened
  float reverseTravel = 0;

  // True if the menu is opened
  boolean menuOpened = false;

  public MenuGesture(ArrayList<TuioCursor> cursors) {
    super(cursors);
  }

  public float evaluatePotential() {
    if (cursors.size() != 2) {
      println("wrong size");
      return Gesture.NO_MATCH;
    }
    
    // Abort if one cursor is removed
    if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED || cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
      println("removed");
      return Gesture.NO_MATCH;
    }
    
    float currentAngle = cursors.get(0).getAngleDegrees(cursors.get(1));
    float currentDistance = getTouchDistance(cursors.get(0),cursors.get(1));
    
    if (!initialized) {
      initialDistance = currentDistance;
      initialAngle = currentAngle;
      lastDistance = currentDistance;
      initialized = true;
      if(initialDistance < minimum_distance || initialDistance > maximum_distance){
        println("initialDistance");
        return Gesture.NO_MATCH;
      }
    }
    
    float travelledDistance =  abs(lastDistance) - abs(currentDistance);
    println(travelledDistance);
    lastDistance = currentDistance;
    
    if(abs(abs(currentAngle)-abs(initialAngle)) > angle_threshold){
      println("angle");
      return Gesture.NO_MATCH;
    }
    
    if(currentDistance < (initialDistance - distance_threshold)){
      println("match");
      detectDistance = currentDistance;
      return Gesture.MATCH;
    }
    
    if(travelledDistance < 0){
      reverseTravel += abs(travelledDistance);
    }
    
    if(reverseTravel > reverse_travle_threshold){
      println("reverse");
      return Gesture.NO_MATCH;
    }
    
    return Gesture.UNCLEAR;
  }

  TuioPoint menuCursor;
  
  TuioPoint menuPosition;
  float menuAngle = 0;
  float menuScale = 0;

  public boolean update() {
    
    
    if( !menuOpened ){
      if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED || cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
        return false;
      }
      float currentAngle = cursors.get(0).getAngleDegrees(cursors.get(1));
      float currentDistance = getTouchDistance(cursors.get(0),cursors.get(1));
      
      if(move_menu || menuPosition == null || menuCursor == null){
        menuPosition = getMiddle(cursors.get(0),cursors.get(1));
        menuCursor = menuPosition;
      }
      if(rotate_menu){
        menuAngle = currentAngle;
      }
      menuScale = 1-((currentDistance-inner_distance)/(detectDistance-inner_distance));
      
      if (currentDistance < inner_distance){
        menuOpened = true;
        menuScale = 1;
      }
    }else{
      if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED && cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
        if(selectedTool != null){
          mapManager.changeTool(selectedTool);
        }
        return false;
      }
      if (cursors.get(0).getTuioState() != TuioCursor.TUIO_REMOVED && cursors.get(1).getTuioState() != TuioCursor.TUIO_REMOVED) {
        menuCursor = getMiddle(cursors.get(0),cursors.get(1));
      }else if(cursors.get(0).getTuioState() != TuioCursor.TUIO_REMOVED){
        menuCursor = cursors.get(0);
      }else{
        menuCursor = cursors.get(1);
      }
      
    }
    
    //draw the menu
    pushMatrix();
    translate(menuPosition.getScreenX(width), menuPosition.getScreenY(height));
    scale(menuScale);
    drawArc();
    
    rotate(-radians(menuAngle));
    
    drawMenu();
    
    //Hacky way to draw the menu again, but mirrored
    menuAngle += 180;
    rotate(radians(180));
    drawMenu();
    menuAngle -= 180;
    
    popMatrix();
    
    return true;
  }
/*
  public void getMenuDirection(){
    if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED && cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
      println("removed");
      return Gesture.NO_MATCH;
    }
  }
*/
  public void drawArc(){
      float menuDirection = -(menuPosition.getAngleDegrees(menuCursor) - 360)%360;
      float menuDistance = getTouchDistance(menuCursor,menuPosition);
      float half_width = 20;
      
      int arc_size = (int)(menu_border_deadzone*(width/touchfield_width)*2);
      int inner_arc_size = (int)(menu_center_deadzone*(width/touchfield_width)*2);
      
      if(menuDistance > menu_center_deadzone && menuDistance < menu_border_deadzone){
        fill(color(0,0,50,128));
      }else{
        fill(color(0,0,50,80));
      }
     
      arc(0, 0, arc_size, arc_size, radians(menuDirection-half_width), radians(menuDirection+half_width));
      arc(0, 0, inner_arc_size, inner_arc_size, radians(menuDirection+half_width), radians(menuDirection-half_width+360));
  }

  public void drawMenu(){
      image(buttons.get("Raise")[0], -250, -125);
      image(buttons.get("Lower")[0], -125, -250);
      image(buttons.get("Smooth")[0], +25, -250);
      image(buttons.get("Special")[0], +150, -125);
      float menuDirection = (menuPosition.getAngleDegrees(menuCursor) - menuAngle + 360)%360;
      float menuDistance = getTouchDistance(menuCursor,menuPosition);
      
      if(menuDistance > menu_center_deadzone && menuDistance < menu_border_deadzone){
        if (menuDirection > 0 && menuDirection < 40) {
          image(buttons.get("Special")[1], +150, -125);
          selectedTool = Tool.SPECIAL;
        } else if (menuDirection > 40 && menuDirection < 90) {
          image(buttons.get("Smooth")[1], +25, -250);
          selectedTool = Tool.BLUR_TERRAIN;
        } else if (menuDirection > 90 && menuDirection < 140) {
          image(buttons.get("Lower")[1], -125, -250);
          selectedTool = Tool.LOWER_TERRAIN;
        } else if (menuDirection > 140 && menuDirection < 180) {
          image(buttons.get("Raise")[1], -250, -125);
          selectedTool = Tool.RAISE_TERRAIN;
        }
      }else{
        selectedTool = null;
      }
  }
}

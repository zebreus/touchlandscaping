public class MenuGesture extends Gesture { //<>// //<>// //<>//
  // Minimal start distance (mm)
  static final float minimum_distance = 30;
  // Maximum start distance (mm)
  static final float maximum_distance = 200;
  // Maximum angle change before impossible (degrees)
  static final float angle_change_threshold = 10;
  // Position change, after which the gesture is triggered (mm)
  static final float position_change_threshold = 10;
  // Maximum distance change before impossible (mm)
  static final float distance_change_threshold = 10;
  // The difference to the initial position for the menu to fully open
  static final float open_menu_position_difference = 40;
  // Whether the menu should rotate
  static final boolean rotate_menu = true;
  // Whether to move the menu after match
  static final boolean move_menu = true;
  // Whether to draw a selection ark
  static final boolean draw_arc = true;
  // Menu center deadzone ( in mm )
  static final float menu_center_deadzone = 15;
  // Menu outside deadzone ( in mm )
  static final float menu_border_deadzone = 60;

  float initialDistance;
  TuioPoint initialPosition;
  TuioTime initialTime;
  float initialAngle;
  TuioPoint triggerPosition;
  boolean initialized = false;
  boolean menuOpened = false;
  float menuAngle;
  float menuScale;
  TuioPoint menuPosition;
  TuioPoint menuCursor;
  Tool selectedTool;

  public MenuGesture(ArrayList<TuioCursor> cursors) {
    super(cursors);
  }

  public boolean update() {
    if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED && cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
      if (selectedTool != null) {
        mapManager.setTool(selectedTool);
      }
      return false;
    }
    // Get current cursor position
    if (cursors.get(0).getTuioState() != TuioCursor.TUIO_REMOVED && cursors.get(1).getTuioState() != TuioCursor.TUIO_REMOVED) {
      menuCursor = getMiddle(cursors.get(0), cursors.get(1));
    } else if (cursors.get(0).getTuioState() != TuioCursor.TUIO_REMOVED) {
      menuCursor = cursors.get(0);
    } else {
      menuCursor = cursors.get(1);
    }

    if ( !menuOpened ) {
      if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED || cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
        return false;
      }
      float currentAngle = cursors.get(0).getAngleDegrees(cursors.get(1));
      float currentDistance = getTouchDistance(initialPosition, menuCursor);
      if (move_menu || menuPosition == null){
        menuPosition = menuCursor;

      }
      
      if (rotate_menu) {
        menuAngle = currentAngle;
      }
      menuScale = (currentDistance/open_menu_position_difference);

      if (currentDistance >= open_menu_position_difference) {
        menuOpened = true;
        menuScale = 1;
      }
    }

    pushMatrix();
    translate(menuPosition.getScreenX(width), menuPosition.getScreenY(height));
    scale(menuScale);
    drawArc();

    rotate(-radians(menuAngle));
    drawMenu();

    menuAngle += 180;
    rotate(radians(180));
    drawMenu();
    menuAngle -= 180;

    popMatrix();

    return true;
  }

  public float evaluatePotential() {
    if (cursors.size() != 2) {
      println("wrong size");
      return Gesture.NO_MATCH;
    }

    if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED || cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
      println("removed");
      return Gesture.NO_MATCH;
    }

    float currentAngle = cursors.get(0).getAngleDegrees(cursors.get(1));
    float currentDistance = getTouchDistance(cursors.get(0), cursors.get(1));
    TuioPoint currentPosition = getMiddle(cursors.get(0), cursors.get(1));
    TuioTime currentTime = TuioTime.getSessionTime();

    if (!initialized) {
      initialDistance = currentDistance;
      initialAngle = currentAngle;
      initialPosition = currentPosition;
      initialTime = currentTime;
      initialized = true;
      if (initialDistance < minimum_distance || initialDistance > maximum_distance) {
        println("initialDistance");
        return Gesture.NO_MATCH;
      }
    }

    if (abs(angleDifference(initialAngle, currentAngle)) > angle_change_threshold) {
      println("angle changed too much");
      return Gesture.NO_MATCH;
    }

    float distanceChange = abs(currentDistance-initialDistance);
    if (distanceChange >= distance_change_threshold) {
      println("distance changed too much");
      return Gesture.NO_MATCH;
    }

    float positionChange =  getTouchDistance(initialPosition, currentPosition);
    if ( positionChange > position_change_threshold ) {
      println("match");
      return Gesture.MATCH;
    }

    return Gesture.UNCLEAR;
  }

  // Calculate the angle difference. the result is between -180 and +180
  float angleDifference(float angleA, float angleB) {
    float angleChange = (((angleA-angleB)%360)+360)%360;
    if ( angleChange > 180 ) {
      angleChange = -360+angleChange;
    }
    return angleChange;
  }

  public void drawArc() {
    float menuDirection = -(menuPosition.getAngleDegrees(menuCursor) - 360)%360;
    float menuDistance = getTouchDistance(menuCursor, menuPosition);
    float half_width = 20;

    int arc_size = (int)(menu_border_deadzone*(width/touchfield_width)*2);
    int inner_arc_size = (int)(menu_center_deadzone*(width/touchfield_width)*2);

    if (menuDistance > menu_center_deadzone && menuDistance < menu_border_deadzone) {
      fill(color(0, 0, 50, 128));
    } else {
      fill(color(0, 0, 50, 80));
    }

    arc(0, 0, arc_size, arc_size, radians(menuDirection-half_width), radians(menuDirection+half_width));
    arc(0, 0, inner_arc_size, inner_arc_size, radians(menuDirection+half_width), radians(menuDirection-half_width+360));
  }


  public void drawMenu() {
    float menuDirection = (menuPosition.getAngleDegrees(menuCursor) - menuAngle + 360)%360;
    float menuDistance = getTouchDistance(menuCursor, menuPosition);

    if (menuDistance > menu_center_deadzone && menuDistance < menu_border_deadzone) {
      if (menuDirection > 0 && menuDirection < 40) {
        selectedTool = Tool.SPECIAL;
      } else if (menuDirection > 40 && menuDirection < 90) {
        selectedTool = Tool.SMOOTH_TERRAIN;
      } else if (menuDirection > 90 && menuDirection < 140) {
        selectedTool = Tool.LOWER_TERRAIN;
      } else if (menuDirection > 140 && menuDirection < 180) {
        selectedTool = Tool.RAISE_TERRAIN;
      }
    } else {
      selectedTool = null;
    }

    Tool setTool = mapManager.getTool();
    int raiseButtonState =   (selectedTool == Tool.RAISE_TERRAIN) ? 1 : (setTool == Tool.RAISE_TERRAIN) ? 2 : 0;
    int lowerButtonState =   (selectedTool == Tool.LOWER_TERRAIN) ? 1 : (setTool == Tool.LOWER_TERRAIN) ? 2 : 0;
    int smoothButtonState =  (selectedTool == Tool.SMOOTH_TERRAIN) ? 1 : (setTool == Tool.SMOOTH_TERRAIN) ? 2 : 0;
    int specialButtonState = (selectedTool == Tool.SPECIAL) ? 1 : (setTool == Tool.SPECIAL) ? 2 : 0;

    image(buttons.get("Raise")[raiseButtonState], -250, -125);
    image(buttons.get("Lower")[lowerButtonState], -125, -250);
    image(buttons.get("Smooth")[smoothButtonState], +25, -250);
    image(buttons.get("Special")[specialButtonState], +150, -125);
  }
}

public class SizeAdjustmentGesture extends Gesture {
  // Minimal start distance (mm)
  static final float minimum_distance = 30;
  // Maximum start distance (mm)
  static final float maximum_distance = 200;
  // Maximum angle change before impossible (degrees)
  static final float angle_change_threshold = 10;
  // Maximum position change before impossible (mm)
  static final float position_change_threshold = 10;
  // Distance change, after which the gesture is triggered
  static final float distance_change_threshold = 10;
  // How much each mm changes the brush size (mm)
  static final float distance_to_size = 0.25;

  float initialDistance;
  TuioPoint initialPosition;
  TuioTime initialTime;
  float initialAngle;
  float lastDistance;
  boolean initialized = false;

  public SizeAdjustmentGesture(ArrayList<TuioCursor> cursors) {
    super(cursors);
  }

  public boolean update() {
    TuioPoint currentPosition = getMiddle(cursors.get(0), cursors.get(1));
    float currentDistance = getTouchDistance(cursors.get(0), cursors.get(1));
    float distanceChange = currentDistance - lastDistance;
    lastDistance = currentDistance;
    println(distanceChange);
    adjustSize(distanceChange);
    stroke(color(0));
    fill(color(0, 0, 50, 128));
    circle(currentPosition.getScreenX(width), currentPosition.getScreenY(height), mapManager.getBrushSize() / screen_pixel_width);

    if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED || cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
      return false;
    }
    return true;
  }

  public void adjustSize(float distanceChange) {
    mapManager.changeBrushSize(distanceChange * distance_to_size / screen_pixel_width);
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
      println(initialPosition.getX());
      initialTime = currentTime;
      initialized = true;
      if (initialDistance < minimum_distance || initialDistance > maximum_distance) {
        println("initialDistance");
        return Gesture.NO_MATCH;
      }
    }

    float positionChange = getTouchDistance(initialPosition, currentPosition);
    if (positionChange > position_change_threshold) {
      println("position changed too much");
      return Gesture.NO_MATCH;
    }

    if (abs(angleDifference(initialAngle, currentAngle)) > angle_change_threshold) {
      println("angle changed too much");
      return Gesture.NO_MATCH;
    }

    float distanceChange = abs(currentDistance - initialDistance);
    if (distanceChange >= distance_change_threshold) {
      println("match");
      lastDistance = currentDistance;
      return Gesture.MATCH;
    }

    return Gesture.UNCLEAR;
  }

  // Calculate the angle difference. the result is between -180 and +180
  float angleDifference(float angleA, float angleB) {
    float angleChange = (((angleA - angleB) % 360) + 360) % 360;
    if (angleChange > 180) {
      angleChange = -360 + angleChange;
    }
    return angleChange;
  }
}

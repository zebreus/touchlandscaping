public class SpecialGesture extends Gesture {
  //The new point has to be older than minimumTime and younger than maximum time
  TuioTime minAge = new TuioTime(200);
  TuioTime maxAge = new TuioTime(1500);

  public SpecialGesture(ArrayList<TuioCursor> cursors) {
    super(cursors);
  }

  public boolean update() {

    if (cursors.get(0).getTuioState() != TuioCursor.TUIO_REMOVED) {
      return true;
    } else {
      
      List<TuioPoint> path = cursors.get(0).getPath();
      int[] pathPointsXY = new int[path.size()*2];
      int i = 0;
      
      for (TuioPoint p : path) {
        pathPointsXY[i] = p.getScreenX(int(touchfield_width));
        pathPointsXY[i+1] = p.getScreenY(int(touchfield_height));
        i+=2;
      }

      one.check(pathPointsXY);

      return false;
    }
  }

  public float evaluatePotential() {
    if (mapManager.getTool() != Tool.SPECIAL) {
      return Gesture.NO_MATCH;
    }

    if (cursors.size() != 1) {
      return Gesture.NO_MATCH;
    }

    TuioTime startTime = cursors.get(0).getStartTime();
    TuioTime maxStartTime = TuioTime.getSessionTime().subtract(minAge);
    TuioTime minStartTime = TuioTime.getSessionTime().subtract(maxAge);
    if (startTime.getTotalMilliseconds() <= maxStartTime.getTotalMilliseconds()) {
      if (startTime.getTotalMilliseconds() >= minStartTime.getTotalMilliseconds()) {
        return Gesture.MATCH;
      } else {
        return Gesture.NO_MATCH;
      }
    } else {
      return Gesture.UNCLEAR;
    }
  }
}

public class TouchManager {

  float maxInitialGestureDistance = 0.5f;

  // When cursors are removed, they are
  // Sets of points, that have no matching gesture and are still mutable
  public ArrayList<ArrayList<TuioCursor>> unrecognizedGestures = new ArrayList<ArrayList<TuioCursor>>();
  // Sets of points, that have no matching gesture
  public ArrayList<Gesture> uncertainGestures = new ArrayList<Gesture>();
  public ArrayList<Gesture> activeGestures = new ArrayList<Gesture>();

  public void addCursor(TuioCursor cursor) {
    ArrayList<TuioCursor> newCursorList = new ArrayList<TuioCursor>();
    newCursorList.add(cursor);

    for (Iterator<ArrayList<TuioCursor>> cursorListIterator = unrecognizedGestures.iterator(); cursorListIterator.hasNext(); ) {
      ArrayList<TuioCursor> cursorList = cursorListIterator.next();
      for (TuioCursor oldCursor : cursorList) {
        if (oldCursor.getDistance(cursor) <= maxInitialGestureDistance) {
          cursorListIterator.remove();
          newCursorList.addAll(cursorList);
          for (Iterator<Gesture> iterator = uncertainGestures.iterator(); iterator.hasNext(); ) {
            Gesture gesture = iterator.next();
            if (cursorList.equals(gesture.getCursors())) {
              iterator.remove();
            }
          }
          break;
        }
      }
    }

    unrecognizedGestures.add(newCursorList);

    //TODO add gesture for all supported gestures
    uncertainGestures.add(new ToolGesture(newCursorList));
    uncertainGestures.add(new MenuGesture(newCursorList));
    //uncertainGestures.add(new ScrollGesture(newCursorList));
    uncertainGestures.add(new SizeAdjustmentGesture(newCursorList));
  }

  public void updateCursor(TuioCursor cursor) {
  }
  public void removeCursor(TuioCursor cursor) {
  }

  public void update() {
    //Evaluate gestures
    for (Iterator<Gesture> iterator = uncertainGestures.iterator(); iterator.hasNext(); ) {
      Gesture gesture = iterator.next(); // TODO: ConcurrentModificationException
      float certainty = gesture.evaluatePotential();
      if (certainty <= Gesture.NO_MATCH) {
        iterator.remove(); // TODO: ConcurrentModificationException
        boolean last = true;
        for (Gesture otherGesture : uncertainGestures) {
          if (otherGesture.getCursors().equals(gesture.getCursors())) {
            last = false;
            break;
          }
        }
        if (last) {
          unrecognizedGestures.remove(gesture.getCursors());
        }
      }
      if (certainty >= Gesture.MATCH) {
        iterator.remove();
        activeGestures.add(gesture);
        unrecognizedGestures.remove(gesture.getCursors());
      }
    }

    for (Iterator<Gesture> iterator = activeGestures.iterator(); iterator.hasNext(); ) {
      Gesture gesture = iterator.next();
      boolean stillActive = gesture.update();
      if ( !stillActive ) {
        iterator.remove();
      }
    }
  }
}

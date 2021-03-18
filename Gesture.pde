public abstract class Gesture {
  public static final float NO_MATCH = 0.0f;
  public static final float UNLIKELY = 0.25f;
  public static final float UNCLEAR = 0.5f;
  public static final float LIKELY = 0.75f;
  public static final float MATCH = 1.0f;
  ArrayList<TuioCursor> cursors;

  public ArrayList<TuioCursor> getCursors() {
    return cursors;
  }

  public Gesture(ArrayList<TuioCursor> cursors) {
    this.cursors = cursors;
  }

  // As long as the gesture is a match update is called
  // You signal the end of the gesture, by returning false
  public abstract boolean update();

  // A potential of 0 means, that the cursors cannot represent this Gesture and it can be deleted
  // A potential between 0 and 1 means, that the cursors could be this gesture
  // A potential of 1 means, that the cursors represent this gesture
  // As soon as the value is one evaluate Potential is no longer called
  public abstract float evaluatePotential();
}

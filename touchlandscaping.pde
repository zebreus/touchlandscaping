import TUIO.*; //<>//
import java.util.Map;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Random;
// declare a TuioProcessing client
TuioProcessing tuioClient;

// these are some helper variables which are use
float cursor_size = 15;
float object_size = 60;
float table_size = 760;
float scale_factor = 1;
PFont font;

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

public class ToolGesture extends Gesture {
  //The new point has to be older than minimumTime and younger than maximum time
  TuioTime minAge = new TuioTime(1000);
  TuioTime maxAge = new TuioTime(10000);

  public ToolGesture(ArrayList<TuioCursor> cursors) {
    super(cursors);
  }

  public boolean update() {
    if (cursors.get(0).getTuioState() != TuioCursor.TUIO_REMOVED) {
      return true;
    } else {
      return false;
    }
  }

  public float evaluatePotential() {
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

public class PinchGesture extends Gesture {
  //The new point has to be older than minimumTime and younger than maximum time
  TuioTime minAge = new TuioTime(100);
  TuioTime maxAge = new TuioTime(1000);
  float initialDistance;
  float initialAngle;
  boolean initialized = false;

  float angleThreshold = 30;
  float distanceThreshold = 0.1;

  public PinchGesture(ArrayList<TuioCursor> cursors) {
    super(cursors);
  }

  boolean menu = false;

  public boolean update() {

    updateMenu();

    if (cursors.get(0).getTuioState() != TuioCursor.TUIO_REMOVED || cursors.get(1).getTuioState() != TuioCursor.TUIO_REMOVED) {
      return true;
    } else {
      return false;
    }
  }

  public float evaluatePotential() {
    if (cursors.size() != 2) {
      return Gesture.NO_MATCH;
    } else {
      if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED || cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
        return Gesture.NO_MATCH;
      }
      if (!initialized) {
        initialDistance =  cursors.get(0).getDistance(cursors.get(1));
        initialAngle = cursors.get(0).getAngleDegrees(cursors.get(1));
        initialized = true;
        return Gesture.UNCLEAR;
      } else {
        float currentAngle = cursors.get(0).getAngleDegrees(cursors.get(1));
        float currentDistance = cursors.get(0).getDistance(cursors.get(1));
        if (abs(currentAngle)-abs(initialAngle) < 30.0f) {
          if (abs(abs(currentDistance)-abs(initialDistance)) > distanceThreshold) {
            return Gesture.MATCH;
          } else {
            return Gesture.UNCLEAR;
          }
        } else {
          return Gesture.NO_MATCH;
        }
      }
    }
  }

  boolean menuePosSet = false;
  TuioPoint menuePos;
  int menueX;
  int menueY;

  public void updateMenu() {
    if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED || cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
      menu = true;
    }

    // Start menueing
    if (menu) {
      //println("Opening menue");
      TuioCursor menueCursor = cursors.get(0);
      if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED) {
        menueCursor = cursors.get(1);
      }

      if (!menuePosSet) {
        menuePos = menueCursor.getPosition();
        menueX = menueCursor.getScreenX(width);
        menueY = menueCursor.getScreenY(height);
        menuePosSet = true;
      }

      // TODO: show actual menue
      stroke(0, 255, 0);
      line(menueX - 300, menueY, menueX + 300, menueY);
      line(menueX, menueY - 300, menueX, menueY + 300);
      if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED && cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
        float menueChoosenAngle = menuePos.getAngleDegrees(menueCursor.getPosition());
        println("Closing menue: " + menueChoosenAngle);
      }
    }
  }
}

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
    uncertainGestures.add(new PinchGesture(newCursorList));
  }

  public void updateCursor(TuioCursor cursor) {
  }
  public void removeCursor(TuioCursor cursor) {
  }
  public void update() {
    //Evaluate gestures
    for (Iterator<Gesture> iterator = uncertainGestures.iterator(); iterator.hasNext(); ) {
      Gesture gesture = iterator.next();
      float certainty = gesture.evaluatePotential();
      if (certainty <= Gesture.NO_MATCH) {
        iterator.remove();
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

TouchManager touchManager = new TouchManager();


boolean verbose = false;
boolean callback = false;

void setup()
{
  //noCursor();
  size(600, 600);
  noStroke();
  fill(0);

  loop();
  frameRate(60);

  font = createFont("Arial", 12);
  scale_factor = height/table_size;

  tuioClient  = new TuioProcessing(this);
}

void draw()
{
  background(255, 255, 255);
  textFont(font, 12*scale_factor);


  String infotext = touchManager.unrecognizedGestures.size() + " unrecognized gestures\n" +
    touchManager.uncertainGestures.size() + " uncertain gestures\n" +
    touchManager.activeGestures.size() + " active gestures\n";

  infotext += "Unrecognized gestures:\n";
  touchManager.update();
  int cursorListCount = 0;
  for (ArrayList<TuioCursor> cursorList : touchManager.unrecognizedGestures) {
    String name = "Unrecognized " + cursorListCount;
    printCursorList(cursorList, name);

    cursorListCount++;
    infotext += "    " + name + "\n";
  }

  infotext += "Uncertain gestures:\n";
  for (Gesture gesture : touchManager.uncertainGestures) {
    String name = gesture.getClass().getSimpleName();
    printCursorList(gesture.getCursors(), name);
    infotext += "    " + name + "\n";
  }

  infotext += "Active gestures:\n";
  for (Gesture gesture : touchManager.activeGestures) {
    String name = gesture.getClass().getSimpleName();
    printCursorList(gesture.getCursors(), name);
    infotext += "    " + name + "\n";
  }

  fill(0);
  text( infotext, (5*scale_factor), (15*scale_factor));
}

void printCursorList(ArrayList<TuioCursor> cursorList, String name) {
  for (TuioCursor cursor : cursorList) {
    printCursor(cursor, name);
  }
}
void printCursorList(ArrayList<TuioCursor> cursorList, String name, color col) {
  for (TuioCursor cursor : cursorList) {
    printCursor(cursor, name, col);
  }
}
void printCursor(TuioCursor cursor) {
  printCursor(cursor, "Cursor");
}
void printCursor(TuioCursor cursor, String name) {
  Random generator = new Random(name.hashCode());
  printCursor(cursor, name, color(generator.nextInt(255), generator.nextInt(255), generator.nextInt(255)));
}
void printCursor(TuioCursor cursor, String name, color col) {
  printCursor(cursor, name, col, (int)cursor.getSessionID());
}
void printCursor(TuioCursor cursor, String name, color col, int number) {
  ArrayList<TuioPoint> pointList = cursor.getPath();
  float cur_size = cursor_size*scale_factor; 

  if (pointList.size()>0) {
    stroke(lerpColor(col, 0, 0.5));
    TuioPoint start_point = pointList.get(0);
    for (int j=0; j<pointList.size(); j++) {
      TuioPoint end_point = pointList.get(j);
      line(start_point.getScreenX(width), start_point.getScreenY(height), end_point.getScreenX(width), end_point.getScreenY(height));
      start_point = end_point;
    }

    stroke(lerpColor(col, 0, 0.5));
    fill(col);
    ellipse( cursor.getScreenX(width), cursor.getScreenY(height), cur_size, cur_size);
    stroke(#FFFFFF);
    fill(0);
    text(""+ number, cursor.getScreenX(width)-(5*scale_factor), cursor.getScreenY(height)+(5*scale_factor));
    text(name, cursor.getScreenX(width)+(5*scale_factor), cursor.getScreenY(height)-(5*scale_factor));
  }
}

void addTuioCursor(TuioCursor tcur) {
  if (verbose) println("add cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY());
  touchManager.addCursor(tcur);
}

// called when a cursor is moved
void updateTuioCursor (TuioCursor tcur) {
  if (verbose) println("set cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY()
    +" "+tcur.getMotionSpeed()+" "+tcur.getMotionAccel());
  touchManager.updateCursor(tcur);
}

void removeTuioCursor(TuioCursor tcur) {
  if (verbose) println("del cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+")");
  touchManager.removeCursor(tcur);
}


// Unused dummy functions.
void addTuioBlob(TuioBlob tblb) {
  if (verbose) println("add blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+") "+tblb.getX()+" "+tblb.getY()+" "+tblb.getAngle()+" "+tblb.getWidth()+" "+tblb.getHeight()+" "+tblb.getArea());
}
void updateTuioBlob (TuioBlob tblb) {
  if (verbose) println("set blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+") "+tblb.getX()+" "+tblb.getY()+" "+tblb.getAngle()+" "+tblb.getWidth()+" "+tblb.getHeight()+" "+tblb.getArea()
    +" "+tblb.getMotionSpeed()+" "+tblb.getRotationSpeed()+" "+tblb.getMotionAccel()+" "+tblb.getRotationAccel());
}
void removeTuioBlob(TuioBlob tblb) {
  if (verbose) println("del blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+")");
}
void addTuioObject(TuioObject tobj) {
  if (verbose) println("add obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle());
}
void updateTuioObject (TuioObject tobj) {
  if (verbose) println("set obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle()
    +" "+tobj.getMotionSpeed()+" "+tobj.getRotationSpeed()+" "+tobj.getMotionAccel()+" "+tobj.getRotationAccel());
}
void removeTuioObject(TuioObject tobj) {
  if (verbose) println("del obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+")");
}
void refresh(TuioTime frameTime) {
  if (verbose) println("frame #"+frameTime.getFrameID()+" ("+frameTime.getTotalMilliseconds()+")");
}

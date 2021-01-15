import de.voidplus.dollar.*; //<>// //<>// //<>// //<>//
import development.*;

import TUIO.*;
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
OneDollar one;

boolean doDebugOverlay = true;

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
    
    mapManager.useTool(cursors.get(0).getPosition());
    
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

  float angleThreshold = 30.0;
  float distanceThreshold = 0.1;
  float distanceToButtonsThreshold = 0.15;

  public PinchGesture(ArrayList<TuioCursor> cursors) {
    super(cursors);
  }

  int menu = -1;

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
        if (abs(abs(currentAngle)-abs(initialAngle)) < angleThreshold) {
          float travelledDistance = abs(currentDistance) - abs(initialDistance);
          if (abs(travelledDistance) > distanceThreshold && travelledDistance < 0) { // Making sure minimum distance travelled towards each other is met
            // TODO: Add min and max time
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
    if (menu < 0) {
      if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED) {
        menu = 1;
      } else if (cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
        menu = 0;
      }
    
    // Start menueing
    } else {
      //println("Opening menue");
      TuioCursor menueCursor = cursors.get(menu);

      if (!menuePosSet) {
        menuePos = menueCursor.getPosition();
        menueX = menueCursor.getScreenX(width);
        menueY = menueCursor.getScreenY(height);
        menuePosSet = true;
      }
          
      image(buttons.get("Raise")[0], menueX-250, menueY-125);
      image(buttons.get("Lower")[0], menueX-125, menueY-250);
      image(buttons.get("Smooth")[0], menueX+25, menueY-250);
      image(buttons.get("Special")[0], menueX+150, menueY-125);
      
      float menueChoosenAngle = menuePos.getAngleDegrees(menueCursor.getPosition());
      Tool selectedTool = Tool.SPECIAL;
      
      if (menuePos.getDistance(menueCursor.getPosition()) > distanceToButtonsThreshold) {
      
        if (menueChoosenAngle > 0 && menueChoosenAngle < 55) {
          image(buttons.get("Special")[1], menueX+150, menueY-125);
          selectedTool = Tool.SPECIAL;
        }
        else if (menueChoosenAngle < 90) {
          image(buttons.get("Smooth")[1], menueX+25, menueY-250);
          selectedTool = Tool.BLUR_TERRAIN;
        }
        else if (menueChoosenAngle < 135) {
          image(buttons.get("Lower")[1], menueX-125, menueY-250);
          selectedTool = Tool.LOWER_TERRAIN;
        }
        else if (menueChoosenAngle < 180) {
          image(buttons.get("Raise")[1], menueX-250, menueY-125);
          selectedTool = Tool.RAISE_TERRAIN;
        }
        
        if (cursors.get(0).getTuioState() == TuioCursor.TUIO_REMOVED && cursors.get(1).getTuioState() == TuioCursor.TUIO_REMOVED) {
          mapManager.changeTool(selectedTool);
          println("Closing menue: " + menueChoosenAngle + " and changed Tool to: " + mapManager.tool.toString());
        }
      }
    }
  }
}

public class ScrollGesture extends Gesture {
  //The new point has to be older than minimumTime and younger than maximum time
  TuioTime minAge = new TuioTime(100);
  TuioTime maxAge = new TuioTime(1000);
  float initialDistance;
  TuioPoint initialDirtyPos;
  TuioPoint initialPos;
  boolean initialized = false;

  float angleThreshold = 20; // Eg. 80°-100° = brushSize up 
  float distanceDeviationThreshold = 0.05;
  float distanceThreshold = 0.05;
  
  int stepMod = 400;  // TODO: Somehow rework the step system to be nicer
  
  public ScrollGesture(ArrayList<TuioCursor> cursors) {
    super(cursors);
  }

  public boolean update() {

    updateScrollActions();

    if (cursors.get(0).getTuioState() != TuioCursor.TUIO_REMOVED && cursors.get(1).getTuioState() != TuioCursor.TUIO_REMOVED) {
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
        initialDistance = cursors.get(0).getDistance(cursors.get(1));
        initialDirtyPos = cursors.get(0).getPosition();
        initialPos = calcPosBetween(initialDirtyPos, cursors.get(1).getPosition());
        initialized = true;
        return Gesture.UNCLEAR;
      } else {
        float currentDistance = cursors.get(0).getDistance(cursors.get(1));
        //println("Distance travelled: " + cursors.get(0).getDistance(initialDirtyPos) + "   Deviation: " + abs(initialDistance - currentDistance));
        if (abs(initialDistance - currentDistance) < distanceDeviationThreshold) {
          float travelledDistance = cursors.get(0).getDistance(initialDirtyPos);
          if (abs(travelledDistance) > distanceThreshold) { // Making sure minimum distance travelled together is met
            // TODO: Add min and max time
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
  
  public TuioPoint calcPosBetween (TuioPoint a, TuioPoint b) {
      float aX = a.getX();
      float aY = a.getY();
      return new TuioPoint(aX + ((b.getX()-aX)/2.0), aY + ((b.getY()-aY)/2.0));
  }

  TuioPoint scrollPos;
  float nextStepX = 0;
  float nextStepY = 0;

  public void updateScrollActions() {  
    // Start scrolling size or intensity
    scrollPos = calcPosBetween(cursors.get(0).getPosition(), cursors.get(1).getPosition());
    nextStepX = -(((scrollPos.getX() - initialPos.getX()) * width) / stepMod);
    nextStepY = (((scrollPos.getY() - initialPos.getY()) * height) / stepMod);
    
    float scrollAngle = initialPos.getAngleDegrees(scrollPos);
    float angleThresholdHalf = angleThreshold / 2;
    boolean validAngle = true;
    
    // TODO: Lock one direction
    if (scrollAngle > 360-angleThresholdHalf || scrollAngle < angleThresholdHalf) { // Right
      mapManager.changeIntensity(nextStepX);
    }          
    else if (scrollAngle > 90-angleThresholdHalf && scrollAngle < 90+angleThresholdHalf) { // Up
      mapManager.changeRadius(nextStepY);
    }      
    else if (scrollAngle > 180-angleThresholdHalf && scrollAngle < 180+angleThresholdHalf) { // Left
      mapManager.changeIntensity(nextStepX);
    }  
    else if (scrollAngle > 270-angleThresholdHalf && scrollAngle < 270+angleThresholdHalf) { // Down
      mapManager.changeRadius(nextStepY);
    }     
    else {
      validAngle = false;
    }
    
    stroke(lineColor);
    fill(color(red(lineColor), green(lineColor), blue(lineColor), round(mapManager.brushIntensityPrecise/100*255)));
    ellipse(initialPos.getScreenX(width), initialPos.getScreenY(height), mapManager.brushRadius*2, mapManager.brushRadius*2); 
    
    if (validAngle && doDebugOverlay) {
      stroke(color(0,255,0));
      line(initialPos.getScreenX(width), initialPos.getScreenY(height), scrollPos.getScreenX(width), scrollPos.getScreenY(height));
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
    uncertainGestures.add(new ScrollGesture(newCursorList));
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

TouchManager touchManager = new TouchManager();
MapManager mapManager;

boolean verbose = false;
boolean callback = false;

PGraphics mapImage;
Map<String, PImage[]> buttons;

void setup()
{
  //noCursor();
  size(1000, 700);
  noStroke();
  fill(0);

  loop();
  frameRate(60);

  font = createFont("Arial", 12);
  scale_factor = height/table_size;

  tuioClient  = new TuioProcessing(this);
  mapManager = new MapManager();
  mapImage = createGraphics(width, height);
  loadButtons();
  
  // Special gesture recognizer
  one = new OneDollar(this);
  one.learn("triangle", new int[] {137,139,135,141,133,144,132,146,130,149,128,151,126,155,123,160,120,166,116,171,112,177,107,183,102,188,100,191,95,195,90,199,86,203,82,206,80,209,75,213,73,213,70,216,67,219,64,221,61,223,60,225,62,226,65,225,67,226,74,226,77,227,85,229,91,230,99,231,108,232,116,233,125,233,134,234,145,233,153,232,160,233,170,234,177,235,179,236,186,237,193,238,198,239,200,237,202,239,204,238,206,234,205,230,202,222,197,216,192,207,186,198,179,189,174,183,170,178,164,171,161,168,154,160,148,155,143,150,138,148,136,148} );
  one.learn("circle", new int[] {127,141,124,140,120,139,118,139,116,139,111,140,109,141,104,144,100,147,96,152,93,157,90,163,87,169,85,175,83,181,82,190,82,195,83,200,84,205,88,213,91,216,96,219,103,222,108,224,111,224,120,224,133,223,142,222,152,218,160,214,167,210,173,204,178,198,179,196,182,188,182,177,178,167,170,150,163,138,152,130,143,129,140,131,129,136,126,139} );
  one.learn("rectangle", new int[] {78,149,78,153,78,157,78,160,79,162,79,164,79,167,79,169,79,173,79,178,79,183,80,189,80,193,80,198,80,202,81,208,81,210,81,216,82,222,82,224,82,227,83,229,83,231,85,230,88,232,90,233,92,232,94,233,99,232,102,233,106,233,109,234,117,235,123,236,126,236,135,237,142,238,145,238,152,238,154,239,165,238,174,237,179,236,186,235,191,235,195,233,197,233,200,233,201,235,201,233,199,231,198,226,198,220,196,207,195,195,195,181,195,173,195,163,194,155,192,145,192,143,192,138,191,135,191,133,191,130,190,128,188,129,186,129,181,132,173,131,162,131,151,132,149,132,138,132,136,132,122,131,120,131,109,130,107,130,90,132,81,133,76,133} );
  one.learn("x", new int[] {87,142,89,145,91,148,93,151,96,155,98,157,100,160,102,162,106,167,108,169,110,171,115,177,119,183,123,189,127,193,129,196,133,200,137,206,140,209,143,212,146,215,151,220,153,222,155,223,157,225,158,223,157,218,155,211,154,208,152,200,150,189,148,179,147,170,147,158,147,148,147,141,147,136,144,135,142,137,140,139,135,145,131,152,124,163,116,177,108,191,100,206,94,217,91,222,89,225,87,226,87,224} );
  one.on("triangle circle rectangle x", "foo");
}

// Special gesture method callbacks, TODO: place in different spot, maybe refactor this whole thing
void foo(String gestureName, float percentOfSimilarity, int startX, int startY, int centroidX, int centroidY, int endX, int endY){
    println("Gesture: " + gestureName + " (" + percentOfSimilarity + "% similar) Start: " + startX + "/" +startY + ", Center: " + centroidX + "/" +centroidY + ", End: " + endX + "/" +endY);
}

void draw()
{
  mapManager.drawToMapImage();
  image(mapImage, 0, 0); 
      
  String infotext = "";
  
  if (doDebugOverlay) {
     infotext += touchManager.unrecognizedGestures.size() + " unrecognized gestures\n" +
      touchManager.uncertainGestures.size() + " uncertain gestures\n" +
      touchManager.activeGestures.size() + " active gestures\n";
  
    infotext += "Unrecognized gestures:\n";
  }
  
  touchManager.update();
    
  if (doDebugOverlay) {
    int cursorListCount = 0;
    for (ArrayList<TuioCursor> cursorList : touchManager.unrecognizedGestures) { // TODO: ConcurrentModificationException
      String name = "Unrecognized " + cursorListCount;
      printCursorList(cursorList, name);
  
      cursorListCount++;
      infotext += "    " + name + "\n";
    }
  
    infotext += "Uncertain gestures:\n";
    for (Gesture gesture : touchManager.uncertainGestures) { // TODO: ConcurrentModificationException
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
      textFont(font, 12*scale_factor);
      fill(0);
      text( infotext, (5*scale_factor), (15*scale_factor));
      text("Radius: " + mapManager.brushRadius, (5*scale_factor), height-(10*scale_factor));
      text("Intensity: " + round(mapManager.brushIntensityPrecise), (5*scale_factor), height-(30*scale_factor));
  }
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

void loadButtons() {
  buttons = new HashMap<String, PImage[]>();
   
  PImage[] buttonArray = new PImage[3];
  buttonArray[0] = loadImage("Buttons_Raise_1.png");
  buttonArray[1] = loadImage("Buttons_Raise_2.png");
  buttonArray[2] = loadImage("Buttons_Raise_3.png");
  buttons.put("Raise", buttonArray.clone());
  
  buttonArray[0] = loadImage("Buttons_Lower_1.png");
  buttonArray[1] = loadImage("Buttons_Lower_2.png");
  buttonArray[2] = loadImage("Buttons_Lower_3.png");
  buttons.put("Lower", buttonArray.clone());
  
  buttonArray[0] = loadImage("Buttons_Smooth_1.png");
  buttonArray[1] = loadImage("Buttons_Smooth_2.png");
  buttonArray[2] = loadImage("Buttons_Smooth_3.png");
  buttons.put("Smooth", buttonArray.clone());

  buttonArray[0] = loadImage("Buttons_Special_1.png");
  buttonArray[1] = loadImage("Buttons_Special_2.png");
  buttonArray[2] = loadImage("Buttons_Special_3.png");
  buttons.put("Special", buttonArray.clone());
}


enum Tool {
  RAISE_TERRAIN,
  LOWER_TERRAIN,
  BLUR_TERRAIN,
  SPECIAL
}

int[][] terrainHeight;
boolean[][] changeOccured;

final color[] heightColors = new color[501];
final color lineColor = color(50,50,50);

class MapManager {
  int brushRadius = 50;
  float brushRadiusPrecise = 50.0;
  int brushIntensity = 10;
  float brushIntensityPrecise = 10.0;
    
  ArrayList<int[]> brushPixels = new ArrayList<int[]>();
  
  Tool tool = Tool.RAISE_TERRAIN;
    
  MapManager() {  
    initTerrainHeight();
    initHeightColors();
    calcBrush(brushRadius);
  }
  
  void drawToMapImage() {
    mapImage.beginDraw();
    mapImage.noStroke();
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        if (changeOccured[row][col]) {
          changeOccured[row][col] = false;
          mapImage.stroke(heightColors[terrainHeight[row][col]]);
          mapImage.point(col, row);  
        }
      }
    }
    mapImage.endDraw();
  }
  
  void useTool(TuioPoint toolPosition) {
    int toolX = round(toolPosition.getX()*width); 
    int toolY = round(toolPosition.getY()*height); 
    
    if (tool == Tool.SPECIAL) {
      one.draw();
      one.track(toolX, toolY);
      
    } else if (tool == Tool.BLUR_TERRAIN) {
      int[][] terrainHeightCopy = terrainHeight;
      
      int smoothingIntensity = max(1, (brushIntensity / 2));
      
      for (int[] pixel : brushPixels) {
        int col = pixel[0] + toolX;
        int row = pixel[1] + toolY;

        if (col > 0 && row > 0 && col < width && row < height) {
          float avg = 0;
          float smoothingDivider = 0;
          
          for (int i = -smoothingIntensity; i <= smoothingIntensity; i++) {
            for (int j = -smoothingIntensity; j <= smoothingIntensity; j++) {
              int coli = col + i;
              int rowj = row + j;
              if (coli > 0 && rowj > 0 && coli < width && rowj < height) {
                float weight = (float(smoothingIntensity - abs(i)) / float(smoothingIntensity * 2)) + (float(smoothingIntensity - abs(j)) / float(smoothingIntensity * 2));
                avg += terrainHeight[rowj][coli] * weight;
                smoothingDivider += weight;
              }
            }
          }
          avg = avg / smoothingDivider;
          terrainHeightCopy[row][col] = round(avg);
        }
      }
      
      for (int[] pixel : brushPixels) {
        int col = pixel[0] + toolX;
        int row = pixel[1] + toolY;
        if (col > 0 && row > 0 && col < width && row < height) {
          changePoint(col, row, terrainHeightCopy[row][col]);
        }
      }
            
    } else {
      for (int[] pixel : brushPixels) {
        int col = pixel[0] + toolX;
        int row = pixel[1] + toolY;
        if (col > 0 && row > 0 && col < width && row < height) {
          if (tool == Tool.RAISE_TERRAIN) {
              changePoint(col, row, constrain(terrainHeight[row][col] + brushIntensity, 0, 500));
          } else if (tool == Tool.LOWER_TERRAIN) {
              changePoint(col, row, constrain(terrainHeight[row][col] - brushIntensity, 0, 500));
          }
        } 
      }
    }
  }
  
  void changeTool (Tool newTool) {
      tool = newTool;
  }
  
  void changeRadius (float change) {
    brushRadiusPrecise -= change;
    brushRadiusPrecise = constrain(brushRadiusPrecise,1,100);
    if (brushRadius != round(brushRadiusPrecise)) {
      brushRadius = round(brushRadiusPrecise);
      calcBrush (brushRadius);
    }
  }
  
  void changeIntensity (float change) {
    brushIntensityPrecise -= change;
    brushIntensityPrecise = constrain(brushIntensityPrecise,1,100);
    brushIntensity = max(1,round(brushIntensityPrecise / 6));
  }
  
  
  void calcBrush (int radius) {
    brushPixels.clear();
    int radiusSquared = radius * radius;
    
    for (int row = -brushRadius; row < brushRadius; row++) {
      for (int col = -brushRadius; col < brushRadius; col++) {
        float distanceSquared = (row) * (row) + (col) * (col);
        if (distanceSquared <= radiusSquared) {
          int[] pixel = {col,row};
          brushPixels.add(pixel);
        }
      } 
    } 
  }
  
  void changePoint (int col, int row, int newValue) {
    terrainHeight[row][col] = newValue;
    changeOccured[row][col] = true; 
  }
  
  void initTerrainHeight() {
    terrainHeight = new int[height][width];
    changeOccured = new boolean[height][width];
    float noiseStep = 0.01;
    
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        // TODO: some more interesting initialization with noise or something
        terrainHeight[row][col] = round(noise(noiseStep * col, noiseStep * row) * 500);
        changeOccured[row][col] = true;
      }
    }
  }
  
  void initHeightColors() {
    heightColors[0] = color(50, 120, 200);
    heightColors[100] = color(150, 200, 255);
    heightColors[200] = color(150, 190, 140);
    heightColors[300] = color(240, 240, 190);
    heightColors[400] = color(170, 135, 80);
    heightColors[500] = color(230, 230, 220);
    
    // TODO: How would a color gradient be better programmed?
    for (int i = 0; i < 100; i++) {
      heightColors[i] = lerpColor(heightColors[0], heightColors[100], float(i)/100);
    }
    
    for (int i = 100; i < 200; i++) {
      heightColors[i] = lerpColor(heightColors[100], heightColors[200], float(i-100)/100);
    }
    
    for (int i = 200; i < 300; i++) {
      heightColors[i] = lerpColor(heightColors[200], heightColors[300], float(i-200)/100);
    }
    
    for (int i = 300; i < 400; i++) {
      heightColors[i] = lerpColor(heightColors[300], heightColors[400], float(i-300)/100);
    }
    
    for (int i = 400; i < 500; i++) {
      heightColors[i] = lerpColor(heightColors[400], heightColors[500], float(i-400)/100);
    }
  }
}

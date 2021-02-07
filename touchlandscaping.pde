import de.voidplus.dollar.*; //<>//
import development.*;

import TUIO.*;
import java.util.Map;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Random;


// Settings now in settings.pde
//Debug cursor width in mm
float cursor_size = 10;

OneDollar one;

TuioProcessing tuioClient;
TouchManager touchManager;
MapManager mapManager;

PGraphics mapImage;


Map<String, PImage[]> buttons;

void settings(){
  System.setProperty("jogl.disable.openglcore", "false");

  //noCursor();
  size(1600, 1000, P2D);
  
}

void setup()
{
  surface.setTitle("Xtreme Touchlandscaping deluxe++");
  mapImage = createGraphics(width, height, P2D);

  fill(0);

  loop();
  frameRate(60);

  setupSettings();

  tuioClient  = new TuioProcessing(this);
  touchManager = new TouchManager();
  mapManager = new MapManager();

  loadButtons();

  mapManager.drawFullMapToImage();

  setupOneDollar();
}
 //<>//
void draw()
{
  mapManager.drawMap();

  showDebugOutput();

  touchManager.update();
  //println(frameRate);
}



void showDebugOutput() {
  String infotext = "";

  if (doDebugOverlay) {
    ArrayList<Gesture> tempUncertainGestures = (ArrayList<Gesture>) touchManager.uncertainGestures.clone();
    ArrayList<Gesture> tempActiveGestures = (ArrayList<Gesture>) touchManager.activeGestures.clone();
    ArrayList<ArrayList<TuioCursor>> tempUnrecognizedGestures = (ArrayList<ArrayList<TuioCursor>>) touchManager.unrecognizedGestures.clone();

    infotext += tempUncertainGestures.size() + " unrecognized gestures\n" +
      tempUncertainGestures.size() + " uncertain gestures\n" +
      tempActiveGestures.size() + " active gestures\n";

    infotext += "Unrecognized gestures:\n";

    int cursorListCount = 0;
    for (ArrayList<TuioCursor> cursorList : tempUnrecognizedGestures) {
      String name = "Unrecognized " + cursorListCount;
      printCursorList(cursorList, name);

      cursorListCount++;
      infotext += "    " + name + "\n";
    }

    infotext += "Uncertain gestures:\n";
    for (Gesture gesture : tempUncertainGestures) {
      String name = gesture.getClass().getSimpleName();
      printCursorList(gesture.getCursors(), name);
      infotext += "    " + name + "\n";
    }

    infotext += "Active gestures:\n";
    for (Gesture gesture : tempActiveGestures) {
      String name = gesture.getClass().getSimpleName();
      printCursorList(gesture.getCursors(), name);
      infotext += "    " + name + "\n";
    }

    textFont(font, 5*screen_scale_factor);
    fill(0);
    text( infotext, (5*screen_scale_factor), (10*screen_scale_factor));
    text("Framerate  : " + frameRate, (5*screen_scale_factor), height-(25*screen_scale_factor));
    text("Intensity: " + mapManager.brushIntensity, (5*screen_scale_factor), height-(15*screen_scale_factor));      
    text("Radius: " + mapManager.brushSize, (5*screen_scale_factor), height-(5*screen_scale_factor));
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
  float cur_size = cursor_size*screen_scale_factor; 

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
    text(""+ number, cursor.getScreenX(width)-(5*screen_scale_factor), cursor.getScreenY(height)+(5*screen_scale_factor));
    text(name, cursor.getScreenX(width)+(5*screen_scale_factor), cursor.getScreenY(height)-(5*screen_scale_factor));
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

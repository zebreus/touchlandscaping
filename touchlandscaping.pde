import de.voidplus.dollar.*; //<>//
import development.*;

import TUIO.*;
import java.util.Map;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Random;


// these are some helper variables which are use
float cursor_size = 15;
float object_size = 60;
float table_size = 760;
float scale_factor = 1;
PFont font;
OneDollar one;

boolean doDebugOverlay = true;

TuioProcessing tuioClient;

TouchManager touchManager = new TouchManager();
MapManager mapManager;


boolean verbose = false;
boolean callback = false;

PGraphics mapImage;
PGraphics ringImage;

Map<String, PImage[]> buttons;

void setup()
{
  //noCursor();
  size(1600, 1000);
  noStroke();
  fill(0);

  loop();
  frameRate(60);

  font = createFont("Arial", 12);
  scale_factor = height/table_size;

  tuioClient  = new TuioProcessing(this);
  mapManager = new MapManager();
  mapImage = createGraphics(width, height);
  ringImage = createGraphics(width, height);
  loadButtons();
  
  // Special gesture recognizer
  one = new OneDollar(this);
  one.learn("triangle", new int[] {137,139,135,141,133,144,132,146,130,149,128,151,126,155,123,160,120,166,116,171,112,177,107,183,102,188,100,191,95,195,90,199,86,203,82,206,80,209,75,213,73,213,70,216,67,219,64,221,61,223,60,225,62,226,65,225,67,226,74,226,77,227,85,229,91,230,99,231,108,232,116,233,125,233,134,234,145,233,153,232,160,233,170,234,177,235,179,236,186,237,193,238,198,239,200,237,202,239,204,238,206,234,205,230,202,222,197,216,192,207,186,198,179,189,174,183,170,178,164,171,161,168,154,160,148,155,143,150,138,148,136,148} );
  one.learn("circle", new int[] {127,141,124,140,120,139,118,139,116,139,111,140,109,141,104,144,100,147,96,152,93,157,90,163,87,169,85,175,83,181,82,190,82,195,83,200,84,205,88,213,91,216,96,219,103,222,108,224,111,224,120,224,133,223,142,222,152,218,160,214,167,210,173,204,178,198,179,196,182,188,182,177,178,167,170,150,163,138,152,130,143,129,140,131,129,136,126,139} );
  one.learn("rectangle", new int[] {78,149,78,153,78,157,78,160,79,162,79,164,79,167,79,169,79,173,79,178,79,183,80,189,80,193,80,198,80,202,81,208,81,210,81,216,82,222,82,224,82,227,83,229,83,231,85,230,88,232,90,233,92,232,94,233,99,232,102,233,106,233,109,234,117,235,123,236,126,236,135,237,142,238,145,238,152,238,154,239,165,238,174,237,179,236,186,235,191,235,195,233,197,233,200,233,201,235,201,233,199,231,198,226,198,220,196,207,195,195,195,181,195,173,195,163,194,155,192,145,192,143,192,138,191,135,191,133,191,130,190,128,188,129,186,129,181,132,173,131,162,131,151,132,149,132,138,132,136,132,122,131,120,131,109,130,107,130,90,132,81,133,76,133} );
  one.learn("x", new int[] {87,142,89,145,91,148,93,151,96,155,98,157,100,160,102,162,106,167,108,169,110,171,115,177,119,183,123,189,127,193,129,196,133,200,137,206,140,209,143,212,146,215,151,220,153,222,155,223,157,225,158,223,157,218,155,211,154,208,152,200,150,189,148,179,147,170,147,158,147,148,147,141,147,136,144,135,142,137,140,139,135,145,131,152,124,163,116,177,108,191,100,206,94,217,91,222,89,225,87,226,87,224} );

  one.learn("box", new int[] {100,100 ,110,100 ,110,110 ,100,110});
  
  one.on("triangle circle rectangle x box", "foo");
}

// Special gesture method callbacks, TODO: place in different spot, maybe refactor this whole thing
void foo(String gestureName, float percentOfSimilarity, int startX, int startY, int centroidX, int centroidY, int endX, int endY){
    println("Gesture: " + gestureName + " (" + percentOfSimilarity + "% similar) Start: " + startX + "/" +startY + ", Center: " + centroidX + "/" +centroidY + ", End: " + endX + "/" +endY);
}

void draw()
{
  mapManager.drawToMapImage();
  if (frameCount % 30 == 0) {
    mapManager.drawRingImage();
  }

  image(mapImage, 0, 0); 
  image(ringImage, 0, 0); 
      
  String infotext = "";
  
  if (doDebugOverlay) {
     infotext += touchManager.unrecognizedGestures.size() + " unrecognized gestures\n" +
      touchManager.uncertainGestures.size() + " uncertain gestures\n" +
      touchManager.activeGestures.size() + " active gestures\n";
  
    infotext += "Unrecognized gestures:\n";

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
      text( infotext, (scale_factor), (15*scale_factor));
      text("Framerate  : " + frameRate, (5*scale_factor), height-(50*scale_factor));
      text("Intensity: " + round(mapManager.brushIntensityPrecise), (5*scale_factor), height-(30*scale_factor));      
      text("Radius: " + mapManager.brushRadius, (5*scale_factor), height-(10*scale_factor));
  }
  
  touchManager.update();
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

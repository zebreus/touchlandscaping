import TUIO.*;
import de.voidplus.dollar.*;
import development.*;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Arrays;
import java.util.ArrayList;

// Settings now in settings.pde
// Debug cursor width in mm
float cursor_size = 10;

OneDollar one;

TuioProcessing tuioClient;
TouchManager touchManager;
MapManager mapManager;

Map<String, PImage[]> buttons;

void settings() {
  System.setProperty("jogl.disable.openglcore", "false");

  size(1600, 1000, P2D);
}

void setup() {
  // frame.setResizable(true);
  surface.setTitle("Xtreme Touchlandscaping deluxe++");

  fill(0);

  loop();
  frameRate(60);

  setupSettings();

  tuioClient = new TuioProcessing(this);
  touchManager = new TouchManager();
  mapManager = new MapManager();

  loadButtons();

  setupOneDollar();
}

void draw() {
  updateSettings();
  
  mapManager.drawMap();

  showDebugOutput();

  touchManager.update();
  
  if(mouseMenu != null){
    boolean menuActive = mouseMenu.update();
    if(!menuActive){
      mouseMenu = null;
    }
  }
}


TuioCursor mouseCursor;
MenuGesture mouseMenu;

void mousePressed(){
  if(mouseControl){
    mouseCursor = new TuioCursor(TuioTime.getSessionTime(), 0,0,float(mouseX)/width,float(mouseY)/height);
    if(mouseButton == LEFT){
      addTuioCursor(mouseCursor);
    }else if(mouseButton == RIGHT){
      ArrayList<TuioCursor> cursors = new ArrayList<TuioCursor>();
      cursors.add(mouseCursor);
      cursors.add(mouseCursor);
      
      mouseMenu = new MenuGesture(cursors);
      mouseMenu.initialPosition = new TuioCursor(mouseCursor);
      mouseMenu.menuPosition = new TuioCursor(mouseCursor);
      mouseMenu.menuOpened = true;
      mouseMenu.menuScale = 1;
    }
  }
}

void mouseDragged(){
  if(mouseControl){
    if(mouseCursor != null){
      mouseCursor.update(TuioTime.getSessionTime(), float(mouseX)/width,float(mouseY)/height);
    }
  }
}

void mouseReleased(){
  if(mouseControl){
    if(mouseCursor != null){
      mouseCursor.remove(TuioTime.getSessionTime());
      removeTuioCursor(mouseCursor);
    }
  }
}

void mouseWheel(MouseEvent event) {
  if(mouseControl){
    final int sizeMultiplier = 5;
    mapManager.changeBrushSize(event.getCount() * sizeMultiplier);
  }
}

void keyPressed() {
  if (key == 'd') {
    drawDebugOverlay = !drawDebugOverlay;
  }
}

void showDebugOutput() {
  String infotext = "";

  if (drawDebugOverlay) {
    ArrayList<Gesture> tempUncertainGestures = (ArrayList<Gesture>) touchManager.uncertainGestures.clone();
    ArrayList<Gesture> tempActiveGestures = (ArrayList<Gesture>) touchManager.activeGestures.clone();
    ArrayList<ArrayList<TuioCursor>> tempUnrecognizedGestures = (ArrayList<ArrayList<TuioCursor>>) touchManager.unrecognizedGestures.clone();

    infotext += tempUncertainGestures.size() + " unrecognized gestures\n" + tempUncertainGestures.size() + " uncertain gestures\n" + tempActiveGestures.size() + " active gestures\n";

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

    textFont(font, 5 * screen_scale_factor);
    fill(0);
    text(infotext, (5 * screen_scale_factor), (10 * screen_scale_factor));
    text("Framerate  : " + frameRate, (5 * screen_scale_factor), height - (25 * screen_scale_factor));
    text("Intensity: " + mapManager.brushIntensity, (5 * screen_scale_factor), height - (15 * screen_scale_factor));
    text("Radius: " + mapManager.brushSize, (5 * screen_scale_factor), height - (5 * screen_scale_factor));
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
  printCursor(cursor, name, col, (int) cursor.getSessionID());
}
void printCursor(TuioCursor cursor, String name, color col, int number) {
  ArrayList<TuioPoint> pointList = cursor.getPath();
  float cur_size = cursor_size * screen_scale_factor;

  if (pointList.size() > 0) {
    stroke(lerpColor(col, 0, 0.5));
    TuioPoint start_point = pointList.get(0);
    for (int j = 0; j < pointList.size(); j++) {
      TuioPoint end_point = pointList.get(j);
      line(start_point.getScreenX(width), start_point.getScreenY(height), end_point.getScreenX(width), end_point.getScreenY(height));
      start_point = end_point;
    }

    stroke(lerpColor(col, 0, 0.5));
    fill(col);
    ellipse(cursor.getScreenX(width), cursor.getScreenY(height), cur_size, cur_size);
    stroke(#FFFFFF);
    fill(0);
    text("" + number, cursor.getScreenX(width) - (5 * screen_scale_factor), cursor.getScreenY(height) + (5 * screen_scale_factor));
    text(name, cursor.getScreenX(width) + (5 * screen_scale_factor), cursor.getScreenY(height) - (5 * screen_scale_factor));
  }
}

void addTuioCursor(TuioCursor tcur) {
  debugPrint("add cur " + tcur.getCursorID() + " (" + tcur.getSessionID() + ") " + tcur.getX() + " " + tcur.getY());
  touchManager.addCursor(tcur);
}

void updateTuioCursor(TuioCursor tcur) {
  debugPrint("set cur " + tcur.getCursorID() + " (" + tcur.getSessionID() + ") " + tcur.getX() + " " + tcur.getY() + " " + tcur.getMotionSpeed() + " " + tcur.getMotionAccel());
  touchManager.updateCursor(tcur);
}

void removeTuioCursor(TuioCursor tcur) {
  debugPrint("del cur " + tcur.getCursorID() + " (" + tcur.getSessionID() + ")");
  touchManager.removeCursor(tcur);
}

// Unused dummy functions.
void addTuioBlob(TuioBlob tblb) {
  debugPrint("add blb " + tblb.getBlobID() + " (" + tblb.getSessionID() + ") " + tblb.getX() + " " + tblb.getY() + " " + tblb.getAngle() + " " + tblb.getWidth() + " " + tblb.getHeight() + " " + tblb.getArea());
}
void updateTuioBlob(TuioBlob tblb) {
  debugPrint("set blb " + tblb.getBlobID() + " (" + tblb.getSessionID() + ") " + tblb.getX() + " " + tblb.getY() + " " + tblb.getAngle() + " " + tblb.getWidth() + " " + tblb.getHeight() + " " + tblb.getArea() + " " + tblb.getMotionSpeed() + " " + tblb.getRotationSpeed() + " " + tblb.getMotionAccel()
        + " " + tblb.getRotationAccel());
}
void removeTuioBlob(TuioBlob tblb) {
  debugPrint("del blb " + tblb.getBlobID() + " (" + tblb.getSessionID() + ")");
}
void addTuioObject(TuioObject tobj) {
  debugPrint("add obj " + tobj.getSymbolID() + " (" + tobj.getSessionID() + ") " + tobj.getX() + " " + tobj.getY() + " " + tobj.getAngle());
}
void updateTuioObject(TuioObject tobj) {
  debugPrint("set obj " + tobj.getSymbolID() + " (" + tobj.getSessionID() + ") " + tobj.getX() + " " + tobj.getY() + " " + tobj.getAngle() + " " + tobj.getMotionSpeed() + " " + tobj.getRotationSpeed() + " " + tobj.getMotionAccel() + " " + tobj.getRotationAccel());
}
void removeTuioObject(TuioObject tobj) {
  debugPrint("del obj " + tobj.getSymbolID() + " (" + tobj.getSessionID() + ")");
}
void refresh(TuioTime frameTime) {
  debugPrint("frame #" + frameTime.getFrameID() + " (" + frameTime.getTotalMilliseconds() + ")");
}

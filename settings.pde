// Touchfield width in mm
static final float touchfield_width = 270;
// Touchfield height in mm (automatic, if same aspect ratio as screen)
static float touchfield_height;
// Screen pixel density
static final float screen_ppi = 100;
// Draw debug overlay
static boolean drawDebugOverlay = false;
// Print debug messages
static final boolean printDebugMessages = false;
// Enable mouse controls
static final boolean mouseControl = true;

// Helper variables, will be set in setup
// A general scaling factor defined width/table_width
static float screen_scale_factor;
// Pixel width in mm table_width/width
static float screen_pixel_width;
// Screen/Window width in mm
static float screen_width;
// Screen height in mm
static float screen_height;


// Default font
static PFont font;

// Get distance between two Points in mm on touchfield
float getTouchDistance(TuioPoint a, TuioPoint b) {
  return dist(a.getX() * touchfield_width, a.getY() * touchfield_height, b.getX() * touchfield_width, b.getY() * touchfield_height);
}

// Get distance between two Points in mm on screen
float getScreenDistance(TuioPoint a, TuioPoint b) {
  return dist(a.getX() * screen_width, a.getY() * screen_height, b.getX() * screen_width, b.getY() * screen_height);
}

// Get distance between two Points in pixels on screen
float getPixelDistance(TuioPoint a, TuioPoint b) {
  return dist(a.getX() * width, a.getY() * height, b.getX() * width, b.getY() * height);
}

// Get the point between two points
TuioPoint getMiddle(TuioPoint a, TuioPoint b) {
  return new TuioPoint((a.getX() + b.getX()) / 2f, (a.getY() + b.getY()) / 2f);
}

// Called after setup is completed
void setupSettings() {
  updateSettings();
  if (touchfield_height == 0.0) {
    touchfield_height = touchfield_width * ((float) height / (float) width);
  }
  font = createFont("SansSerif", 12);
}

void updateSettings() {
  screen_width = width*25.4/screen_ppi;
  screen_height = height*25.4/screen_ppi;
  screen_scale_factor = width / screen_width;
  screen_pixel_width = screen_width / width;
}

// Loads button images to easily access when menue is called
void loadButtons() {
  buttons = new HashMap<String, PImage[]>();

  PImage[] buttonArray = new PImage[3];
  buttonArray[0] = loadImage("Buttons_Raise_1.png");
  buttonArray[1] = loadImage("Buttons_Raise_2.png");
  buttonArray[2] = loadImage("Buttons_Raise_3.png");
  buttons.put("Raise", buttonArray);

  buttonArray = new PImage[3];
  buttonArray[0] = loadImage("Buttons_Lower_1.png");
  buttonArray[1] = loadImage("Buttons_Lower_2.png");
  buttonArray[2] = loadImage("Buttons_Lower_3.png");
  buttons.put("Lower", buttonArray);

  buttonArray = new PImage[3];
  buttonArray[0] = loadImage("Buttons_Smooth_1.png");
  buttonArray[1] = loadImage("Buttons_Smooth_2.png");
  buttonArray[2] = loadImage("Buttons_Smooth_3.png");
  buttons.put("Smooth", buttonArray);

  buttonArray = new PImage[3];
  buttonArray[0] = loadImage("Buttons_Special_1.png");
  buttonArray[1] = loadImage("Buttons_Special_2.png");
  buttonArray[2] = loadImage("Buttons_Special_3.png");
  buttons.put("Special", buttonArray);
}

<T> void debugPrint(T message){
  if(printDebugMessages){
    println(message);
  }
}

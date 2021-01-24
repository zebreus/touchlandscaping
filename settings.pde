// Touchfield width in mm
float touchfield_width = 270;
// Touchfield height (automatic, if same aspect ratio as screen)
float touchfield_height;
// Screen/Window width in mm
float screen_width = 440;
// Draw debug overlay
boolean doDebugOverlay = true;
// Generate verbose output
boolean verbose = false;

// Helper variables, will be set in setup
// A general scaling factor defined width/table_width
float screen_scale_factor;
// Pixel width in mm table_width/width
float screen_pixel_width;
// Screen height
float screen_height;

// Get distance between two Points in mm on touchfield
float getTouchDistance(TuioPoint a, TuioPoint b){
  return dist(a.getX()*touchfield_width, a.getY()*touchfield_height, b.getX()*touchfield_width, b.getY()*touchfield_height);
}

// Get distance between two Points in mm on screen
float getScreenDistance(TuioPoint a, TuioPoint b){
  return dist(a.getX()*screen_width, a.getY()*screen_height, b.getX()*screen_width, b.getY()*screen_height);
}

// Get distance between two Points in pixels on screen
float getPixelDistance(TuioPoint a, TuioPoint b){
  return dist(a.getX()*width, a.getY()*height, b.getX()*width, b.getY()*height);
}

// Get the point between two points
TuioPoint getMiddle(TuioPoint a, TuioPoint b){
  return new TuioPoint((a.getX()+b.getX())/2f,(a.getY()+b.getY())/2f);
}

// Called after setup is completed
void setupSettings(){
  screen_scale_factor = width/screen_width;
  screen_pixel_width = screen_width/width;
  screen_height = height*screen_pixel_width;
  if(touchfield_height == 0.0){
    touchfield_height = touchfield_width*((float)height/ (float)width);
  }
}

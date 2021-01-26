class MapManager {
  int[][] terrainHeight;

  final color[] heightColors = new color[501];
  final color lineColor = color(0, 0, 0, 40);
  final color transparentColor = color(0, 0, 0, 0);

  int brushRadius = 50;
  int brushRadiusCache = brushRadius;
  int brushIntensity = 20;
  int brushIntensityCache = brushIntensity;

  //These are obsolete
  int stepFactor = 20;  // -> 500 / stepFactor = Number of distinct colors
  int stepsPerLine = 1; // Controlls how many colors are inbetween lines

  float[][] brushPixels;
  int[][] brushPixelsWithIntensity;

  Tool tool = Tool.RAISE_TERRAIN;
  
  PShader mapShader;

  MapManager() {  
    initTerrainHeight();
    prepareMapShader();
    calcBrush(brushRadius);
  }

  void drawFullMapToImage() {
    // Needed to initialize pixel array
    mapImage.beginDraw();
    mapImage.rect(0, 0, width, height);
    mapImage.endDraw();

    mapImage.loadPixels();
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        changePoint(col, row);
      }
    }
    mapImage.updatePixels();
  }

  void useTool(TuioPoint toolPosition) {
    int toolX = round(toolPosition.getX()*width); 
    int toolY = round(toolPosition.getY()*height); 

    {

      mapImage.loadPixels();
      int[][] terrainHeightCopy = null;

      if (tool == Tool.SMOOTH_TERRAIN) {

        terrainHeightCopy = terrainHeight;
        int smoothingIntensity = max(1, floor(brushIntensity / 10));

        for (int row = 0; row < brushPixels.length; row++) {
          for (int col = 0; col < brushPixels[0].length; col++) {

            if (brushPixels[row][col] != 0) {

              int colCorrected = col + toolX - brushRadius;
              int rowCorrected = row + toolY - brushRadius;

              if (colCorrected > 0 && rowCorrected > 0 && colCorrected < width && rowCorrected < height) {
                float avg = 0;
                float smoothingDivider = 0;

                for (int i = -smoothingIntensity; i <= smoothingIntensity; i++) {
                  for (int j = -smoothingIntensity; j <= smoothingIntensity; j++) {
                    int coli = colCorrected + i;
                    int rowj = rowCorrected + j;

                    if (coli > 0 && rowj > 0 && coli < width && rowj < height) {
                      float weight = (float(smoothingIntensity - abs(i)) / float(smoothingIntensity * 2)) + (float(smoothingIntensity - abs(j)) / float(smoothingIntensity * 2));
                      avg += terrainHeight[rowj][coli] * weight;
                      smoothingDivider += weight;
                    }
                  }
                }
                avg = avg / smoothingDivider;
                terrainHeightCopy[rowCorrected][colCorrected] = round(avg);
              }
            }
          }
        }
      }

      if (tool == Tool.RAISE_TERRAIN || tool == Tool.LOWER_TERRAIN || tool == Tool.SMOOTH_TERRAIN) {

        for (int row = 0; row < brushPixels.length; row++) {
          for (int col = 0; col < brushPixels[0].length; col++) {

            int colCorrected = col + toolX - brushRadius;
            int rowCorrected = row + toolY - brushRadius;

            if (colCorrected > 0 && rowCorrected > 0 && colCorrected < width && rowCorrected < height) {
              if (tool == Tool.RAISE_TERRAIN) {
                changePoint(colCorrected, rowCorrected, constrain(terrainHeight[rowCorrected][colCorrected] + brushPixelsWithIntensity[row][col], -500, 1000));
              } else if (tool == Tool.LOWER_TERRAIN) {
                changePoint(colCorrected, rowCorrected, constrain(terrainHeight[rowCorrected][colCorrected] - brushPixelsWithIntensity[row][col], -500, 1000));
              } else if (tool == Tool.SMOOTH_TERRAIN && terrainHeightCopy != null) {
                changePoint(colCorrected, rowCorrected, terrainHeightCopy[rowCorrected][colCorrected]);
              }
            }
          }
        }
      }
      mapImage.updatePixels();
    }
  }

  void setTool(Tool newTool) {
    tool = newTool;
  }

  Tool getTool() {
    return tool;
  }

  void cacheSizeIntensity() {
    brushRadiusCache = brushRadius;
    brushIntensityCache = brushIntensity;
  }

  void changeRadius (int relativeValue) {
    if (relativeValue != 0) {
      brushRadius = constrain(brushRadiusCache + relativeValue, 1, 100);

      calcBrush (brushRadius);
    }
  }

  void changeIntensity (int relativeValue) {
    if (relativeValue != 0) {
      brushIntensity = constrain(brushIntensityCache + relativeValue, 1, 100);

      for (int row = 0; row < brushPixels.length; row++) {
        for (int col = 0; col < brushPixels[0].length; col++) {
          brushPixelsWithIntensity[row][col] = round(brushPixels[row][col] * brushIntensity / 10);
        }
      }
    }
  }

  void calcBrush (int radius) {
    int widthHeight = (radius * 2) + 1;
    brushPixels = new float[widthHeight][widthHeight];
    brushPixelsWithIntensity = new int[widthHeight][widthHeight];

    int radiusSquared = radius * radius;

    for (int row = 0; row < widthHeight; row++) {
      for (int col = 0; col < widthHeight; col++) {

        int colCorrected = col - radius;
        int rowCorrected = row - radius;

        float distanceSquared = (rowCorrected) * (rowCorrected) + (colCorrected) * (colCorrected);

        if (distanceSquared <= radiusSquared) {
          brushPixels[row][col] = 1 - (distanceSquared / radiusSquared);
        } else {
          brushPixels[row][col] = 0;
        }
        brushPixelsWithIntensity[row][col] = round(brushPixels[row][col] * brushIntensity / 10);
      }
    }
  }

  void changePoint(int col, int row) {
    changePoint(col, row, terrainHeight[row][col]);
  }

  void changePoint(int col, int row, int newValue) {
    terrainHeight[row][col] = newValue;
    mapImage.pixels[row * mapImage.width + col] = color(newValue/4);
  }

  void drawLegendKeyImage() {
    legendKeyImage.beginDraw();

    // TODO: put this in settings and name it in a useful way...
    legendKeyImage.stroke(color(80, 80, 80));
    legendKeyImage.fill(color(130, 130, 130));
    int legendWidth = 80;
    int legendHeight = 520;
    int marginBottomRight = 20;
    int marginBox = (legendHeight - 500) / 2;
    int marginBottomLines = marginBox + marginBottomRight;
    int cornerRoundness = 9;

    legendKeyImage.rect(width-legendWidth-marginBottomRight, height-legendHeight-marginBottomRight, 
      legendWidth, legendHeight, cornerRoundness, cornerRoundness, cornerRoundness, cornerRoundness);

    for (int h = 0; h < 500; h++) {
      legendKeyImage.stroke(heightColors[h]);
      legendKeyImage.line(width-legendWidth-marginBottomRight+10, height-marginBottomLines-h, width-10-marginBottomRight, height-marginBottomLines-h);

      // Lines on legend key
      if (h % stepFactor * stepsPerLine == 0) {
        legendKeyImage.stroke(lineColor);
        legendKeyImage.line(width-legendWidth-marginBottomRight+10, height-marginBottomLines-h, width-10-marginBottomRight, height-marginBottomLines-h);
      }
    }

    legendKeyImage.stroke(color(80, 80, 80));
    strokeWeight(4);
    legendKeyImage.noFill();
    legendKeyImage.rect(width-legendWidth-marginBottomRight+marginBox, height-legendHeight-marginBottomRight+marginBox, 
      legendWidth-marginBox*2, legendHeight-marginBox*2, 1, 1, 1, 1);   

    legendKeyImage.endDraw();
  }

  void initTerrainHeight() {
    terrainHeight = new int[height][width];
    float noiseStep = 0.008; // FROM max ~0.03 Small detailled 'rocks'
    float noiseStepBaseHeight = 0.003; // TO min ~0.005 Large 'plains'

    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        int noiseBaseHeight = round(noise(noiseStepBaseHeight * col, noiseStepBaseHeight * row) * 200);
        terrainHeight[row][col] = round(noise(noiseStep * col, noiseStep * row) * 1100) - 250 - noiseBaseHeight;
      }
    }

    // TODO: Combine this smoothing step with the brush code, they are too similar!
    for (int row = 1; row < height; row++) {
      for (int col = 1; col < width; col++) {
        float avg = 0;
        float smoothingDivider = 0;
        int smoothingIntensityFull = 2;

        for (int i = -smoothingIntensityFull; i <= smoothingIntensityFull; i++) {
          for (int j = -smoothingIntensityFull; j <= smoothingIntensityFull; j++) {
            int coli = col + i;
            int rowj = row + j;

            if (coli > 0 && rowj > 0 && coli < width && rowj < height) {
              float weight = (float(smoothingIntensityFull - abs(i)) / float(smoothingIntensityFull * 2)) + (float(smoothingIntensityFull - abs(j)) / float(smoothingIntensityFull * 2));
              avg += terrainHeight[rowj][coli] * weight;
              smoothingDivider += weight;
            }
          }
        }
        avg = avg / smoothingDivider;
        terrainHeight[row][col] = round(avg);
      }
    }
    
    // Clean values
    int min = 99999;
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        if(terrainHeight[row][col]<min){
          min = terrainHeight[row][col];
        }
      }
    }
    //Remove negative values and cap at 1023
    //TODO It would probably be a really good idea to store the height as a float between 0 and 1
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        terrainHeight[row][col] -= min;
        if(terrainHeight[row][col] > 1023){
          terrainHeight[row][col] = 1023;
        }
      }
    }
  }
  
  void drawMap(){
    // For some reason only updated points get redrawn and shaded, this can probably be optimized by a lot
    //TODO optimize
    for(int h = 0; h < height ; h++){
    for(int w = 0; w < width ; w++){
      changePoint(w,h);
    }
    }

    shader(mapShader);
    image(mapImage, 0, 0);
    resetShader();
  }

  PImage generateColorTexture(color[] colors, float[] positions) throws Exception{
    if(colors.length != positions.length){
      throw new Exception("NOPE");
    }
    
    // Has to start with 0
    if(positions[0] != 0.0){
      throw new Exception("NOPE");
    }
    
    // Has to end with 1
    if(positions[positions.length-1] != 1.0){
      throw new Exception("NOPE");
    }
    
    // Positions need to increase
    for(int testPos = 1; testPos < positions.length; testPos++){
      if(positions[testPos] <= positions[testPos-1]){
        throw new Exception("NOPE");
      }
    }
    
    PGraphics g = createGraphics(255,1);
    g.beginDraw();
    
    for(int step = 1; step < positions.length ; step++){
      
      for(int pos = int(positions[step-1]*255f) ; pos < positions[step]*255 ; pos++){
        // This has a lot of potential for improvment, but it is only excuted once
        g.stroke(g.lerpColor(colors[step-1],colors[step], float(pos-int(positions[step-1]*255f))/float(int(positions[step]*255f)-int(positions[step-1]*255f)) ));
        g.point(pos,0);
      }
    }
    g.endDraw();
    return g.get(0,0,255,1);
  }

  void prepareMapShader() {
    color[] colors = new color[6]; //<>//
    colors[0] = color(50, 120, 200);
    colors[1] = color(150, 200, 255);
    colors[2] = color(150, 190, 140);
    colors[3] = color(240, 240, 190);
    colors[4] = color(170, 135, 80);
    colors[5] = color(230, 230, 220);

    float[] positions = new float[6];
    positions[0] = 0f;
    positions[1] = 0.2f;
    positions[2] = 0.4f;
    positions[3] = 0.6f;
    positions[4] = 0.8f;
    positions[5] = 1f;
    
    PImage colorTexture;
    try{
      colorTexture = generateColorTexture(colors, positions);
    }catch(Exception e){
      println("EXCEPTION: " + e);
      return;
    }
    
    mapShader = loadShader("mapshader.glsl");
    mapShader.set("steps", 15);
    mapShader.set("shadingIntensity", 15);
    mapShader.set("lineIntensity", 0.4f);
    mapShader.set("colorTexture",colorTexture);
  }
}

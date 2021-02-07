class MapManager { //<>//
  int[][] terrainHeight;

  final color[] heightColors = new color[501];
  final color lineColor = color(0, 0, 0, 40);
  final color transparentColor = color(0, 0, 0, 0);

  // Brush radius in mm
  //TODO change brush radius actually to mm
  float brushSize = 50.0;
  // Brush intensity multiplier
  float brushIntensity = 1.0;
  
  // The maximum size the brush can be.
  int max_brush_size = 500;


  // Relevant for the legend markings
  // The height of the lowest possible point in meters
  int lowestElevation = -4250;
  // The height of the highest possible point in meters
  int elevationRange = 8500;

  // Legend dimensions
  int legendWidth = 160;
  int legendHeight = 600;
  int legendSideMargin = 10;
  int legendTopMargin = 10;
  float legendTextPart = 0.40;

  float[][] brush;

  Tool tool = Tool.RAISE_TERRAIN;

  PShader mapShader;

  int steps = 34;
  PImage colorTexture;
  PImage legendImage;

  MapManager() {  
    initTerrainHeight();
    prepareMapShader();
    prepareLegendKeyImage();
    prepareBrush();
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

  // Get the brush value at the given coordinates of the brush.
  // The input values are between 0 and brushSize
  float brushAt(int x, int y){
    float scalingFactor = float(max_brush_size)/brushSize;
    return brush[int(scalingFactor*x)][int(scalingFactor*y)] * brushIntensity;
  }
/*
  void useTool(TuioPoint toolPosition) {
    int toolX = round(toolPosition.getX()*width);
    int toolY = round(toolPosition.getY()*height);

    {

      mapImage.loadPixels();
      int[][] terrainHeightCopy = null;

      if (tool == Tool.SMOOTH_TERRAIN) {

        terrainHeightCopy = terrainHeight;
        int smoothingIntensity = max(1, floor(brushIntensity / 10));

        for (int row = 0; row < int(brushSize); row++) {
          for (int col = 0; col < int(brushSize); col++) {
            
            //TODO ask kyrill how this works
            //TODO adjust for static brush[][]
            if (brush[row][col] != 0) {

              int colCorrected = col + toolX - int(brushSize);
              int rowCorrected = row + toolY - int(brushSize);

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

        for (int x = 0; x < int(brushSize); x++) {
          for (int y = 0; y < int(brushSize); y++) {

            int colCorrected = x + toolX - int(brushSize/2);
            int rowCorrected = y + toolY - int(brushSize/2);

            if (colCorrected > 0 && rowCorrected > 0 && colCorrected < width && rowCorrected < height) {
              if (tool == Tool.RAISE_TERRAIN) {
                changePoint(colCorrected, rowCorrected, constrain(terrainHeight[rowCorrected][colCorrected] + int(brushAt(x,y)), -500, 1000));
              } else if (tool == Tool.LOWER_TERRAIN) {
                changePoint(colCorrected, rowCorrected, constrain(terrainHeight[rowCorrected][colCorrected] - int(brushAt(x,y)), -500, 1000));
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
*/

    void useTool(TuioPoint toolPosition) {
    int toolX = round(toolPosition.getX()*width);
    int toolY = round(toolPosition.getY()*height);


        for (int x = 0; x < int(brushSize); x++) {
          for (int y = 0; y < int(brushSize); y++) {
            float intensity = brushAt(x,y);
            int colCorrected = x + toolX - int(brushSize/2);
            int rowCorrected = y + toolY - int(brushSize/2);

            if (colCorrected > 0 && rowCorrected > 0 && colCorrected < width && rowCorrected < height) {
              switch(tool){
              case RAISE_TERRAIN:
                changePoint(colCorrected, rowCorrected, constrain(terrainHeight[rowCorrected][colCorrected] + int(intensity), -500, 1000));
                break;
              case LOWER_TERRAIN:
                changePoint(colCorrected, rowCorrected, constrain(terrainHeight[rowCorrected][colCorrected] - int(intensity), -500, 1000));
                break;
              case SMOOTH_TERRAIN:
              case SPECIAL:
              }
            }
          }
        }
      mapImage.updatePixels();
  }

  void setTool(Tool newTool) {
    tool = newTool;
  }

  Tool getTool() {
    return tool;
  }

  void changeBrushSize (float size) {
    brushSize = constrain(brushSize + size, 10, max_brush_size);
  }
  
  //Return the brush radius in mm
  float getBrushSize () {
    //TODO rewrite the brush system
    //return brushPixels.length/2;
    return brushSize/2;
  }

  void changeBrushIntensity (float intensity) {
    brushIntensity += intensity;
  }

  void prepareBrush () {
    float[][] squareBrush = new float[max_brush_size][max_brush_size];

    for (int x = 0; x < max_brush_size; x++) {
      for (int y = 0; y < max_brush_size; y++) {
        squareBrush[x][y] = 1.0;
      }
    }
    
    brush = squareBrush;
    /*
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
    }*/
  }

  void changePoint(int col, int row) {
    changePoint(col, row, terrainHeight[row][col]);
  }

  void changePoint(int col, int row, int newValue) {
    terrainHeight[row][col] = newValue;
    mapImage.pixels[row * mapImage.width + col] = color(newValue/4);
  }

  color getStepColor(int step) {
    if (step < 0 || step > steps-1) {
      return #000000 ;
    }
    int pos = int((float(step)/float(steps))*255f);
    return colorTexture.pixels[pos];
  }

  int getStepElevation(int step) {
    if (step < 0 || step > steps) {
      return 0 ;
    }
    return lowestElevation+int(step*(float(elevationRange)/steps));
  }

  void drawLegendField(PGraphics g, int step, int width, int height) {
    g.stroke(#000000);
    g.fill(getStepColor(step));
    g.rect(0, 0, width, height);
  }

  void drawLegendMeterMarking(PGraphics g, int step) {
    g.fill(#000000);
    g.textAlign(LEFT, CENTER);
    g.text(getStepElevation(step)+"m", 0, 0);
  }

  void prepareLegendKeyImage() {
    PGraphics g = createGraphics(legendWidth, legendHeight);
    g.beginDraw();

    // Some name values
    int fieldHeight = (legendHeight-(legendTopMargin*2))/(steps+1);
    int textWidth = int((legendWidth-(legendSideMargin*2))*legendTextPart);
    int fieldWidth = (legendWidth-(legendSideMargin*2))-textWidth;

    // Draw background
    g.noStroke();
    g.fill(255);
    g.rect(0, 0, legendWidth, legendHeight, 9, 9, 9, 9);

    //Prepare for contents
    g.pushMatrix();
    g.translate(legendSideMargin, legendTopMargin+(fieldHeight/2));

    // Draw colored fields
    g.pushMatrix();
    g.translate(textWidth, 0);
    for (int step = steps-1; step >= 0; step--) {
      drawLegendField(g, step, fieldWidth, fieldHeight);
      g.translate(0, fieldHeight);
    }
    g.popMatrix();

    // Draw meter markings
    g.pushMatrix();
    g.translate(0, 0);
    for (int step = steps; step >= 0; step--) {

      drawLegendMeterMarking(g, step);
      g.translate(0, fieldHeight);
    }
    g.popMatrix();

    g.endDraw();
    legendImage = g.get(0, 0, legendWidth, legendHeight);
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
        if (terrainHeight[row][col]<min) {
          min = terrainHeight[row][col];
        }
      }
    }
    //Remove negative values and cap at 1023
    //TODO It would probably be a really good idea to store the height as a float between 0 and 1
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        terrainHeight[row][col] -= min;
        if (terrainHeight[row][col] > 1023) {
          terrainHeight[row][col] = 1023;
        }
      }
    }
  }

  void drawMap() {
    // For some reason only updated points get redrawn and shaded, this can probably be optimized by a lot
    //TODO optimize
    for (int h = 0; h < height; h++) {
      for (int w = 0; w < width; w++) {
        changePoint(w, h);
      }
    }

    pushMatrix();
    shader(mapShader);
    image(mapImage, 0, 0);
    resetShader();
    popMatrix();
    image(legendImage, 0, 0);
  }

  PImage generateColorTexture(color[] colors, float[] positions) throws Exception {
    if (colors.length != positions.length) {
      throw new Exception("NOPE");
    }

    // Has to start with 0
    if (positions[0] != 0.0) {
      throw new Exception("NOPE");
    }

    // Has to end with 1
    if (positions[positions.length-1] != 1.0) {
      throw new Exception("NOPE");
    }

    // Positions need to increase
    for (int testPos = 1; testPos < positions.length; testPos++) {
      if (positions[testPos] < positions[testPos-1]) {
        throw new Exception("NOPE");
      }
    }

    PGraphics g = createGraphics(255, 1);
    g.beginDraw();

    for (int step = 1; step < positions.length; step++) {
      for (int pos = int(positions[step-1]*255f); pos < positions[step]*255; pos++) {
        g.noStroke();
        g.fill(lerpColor(colors[step-1], colors[step], float(pos-int(positions[step-1]*255f))/float(int(positions[step]*255f)-int(positions[step-1]*255f)) ));
        // Point does for some reason not paint the color accuratly, so rect is used
        g.rect(pos, 0, 1, 1);
      }
    }
    g.endDraw();
    return g.get(0, 0, 255, 1);
  }

  void prepareMapShader() {
    int steps = 34;

    color[] colors = new color[7];
    colors[0] = color(99, 159, 211);
    colors[1] = color(227, 244, 254);
    colors[2] = color(164, 217, 154);
    colors[3] = color(129, 192, 116);
    colors[4] = color(243, 240, 194);
    colors[5] = color(194, 140, 33);
    colors[6] = color(175, 91, 0);

    float[] positions = new float[7];
    positions[0] = 0f;
    positions[1] = float((steps/2)-1)/steps;
    positions[2] = 0.5f;
    positions[3] = float((steps/2)+1)/steps;
    positions[4] = 0.67f;
    positions[5] = 0.9f;
    positions[6] = 1f;

    try {
      colorTexture = generateColorTexture(colors, positions);
    }
    catch(Exception e) {
      println("EXCEPTION: " + e);
      return;
    }

    mapShader = loadShader("mapshader.glsl");
    mapShader.set("steps", steps);
    mapShader.set("shadingIntensity", 2);
    mapShader.set("lineIntensity", 0.2f);
    mapShader.set("colorTexture", colorTexture);
  }
}

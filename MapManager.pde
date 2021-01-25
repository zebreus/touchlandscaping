class MapManager {
  int[][] terrainHeight;

  final color[] heightColors = new color[501];
  final color lineColor = color(0, 0, 0, 40);
  final color transparentColor = color(0, 0, 0, 0);

  int brushRadius = 50;
  int brushRadiusCache = brushRadius;
  int brushIntensity = 20;
  int brushIntensityCache = brushIntensity;

  int stepFactor = 20;
  int stepsPerLine = 1;

  float[][] brushPixels;
  int[][] brushPixelsWithIntensity;

  Tool tool = Tool.RAISE_TERRAIN;

  MapManager() {  
    initTerrainHeight();
    initHeightColors();
    calcBrush(brushRadius);
  }

  void drawFullMapToImage() {
    // Needed to initialize pixel array
    mapImage.beginDraw();
    mapImage.rect(0, 0, width, height);
    mapImage.endDraw();

    ringImage.beginDraw();
    ringImage.rect(0, 0, width, height);
    ringImage.endDraw();

    mapImage.loadPixels();
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        changePoint(col, row);
      }
    }
    mapImage.updatePixels();

    ringImage.loadPixels();
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        drawPointForLines(col, row);
      }
    }
    ringImage.updatePixels();
  }

  void useTool(TuioPoint toolPosition) {
    int toolX = round(toolPosition.getX()*width); 
    int toolY = round(toolPosition.getY()*height); 

    if (tool == Tool.SPECIAL) {
      one.draw();
      one.track(toolX, toolY);
    } else {

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

      ringImage.loadPixels();
      for (int row = 0; row < brushPixels.length; row++) {
        for (int col = 0; col < brushPixels[0].length; col++) {

          int colCorrected = col + toolX - brushRadius;
          int rowCorrected = row + toolY - brushRadius;

          drawPointForLines(colCorrected, rowCorrected);
        }
      }
      ringImage.updatePixels();
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
    mapImage.pixels[row * mapImage.width + col] = heightColors[constrain(newValue, 0, 500)];
  }

  void drawPointForLines(int col, int row) {
    if (col > 0 && row > 0 && col < width && row < height) {
      if (isPointEdge(col, row)) {
        ringImage.pixels[row * mapImage.width + col] = lineColor;
      } else {
        ringImage.pixels[row * mapImage.width + col] = transparentColor;
      }
    }
  }

  boolean isPointEdge(int col, int row) {
    float sum = 0;

    sum += int(terrainHeight[row-1][col-1] / (stepFactor * stepsPerLine));
    sum += int(terrainHeight[row][col-1] / (stepFactor * stepsPerLine));
    sum += int(terrainHeight[row-1][col] / (stepFactor * stepsPerLine));
    sum += int(terrainHeight[row][col] / (stepFactor * stepsPerLine)) * -3;


    if (sum != 0) {
      return true;
    }
    return false;
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
      int imod = int(i / stepFactor);
      heightColors[i] = lerpColor(heightColors[0], heightColors[100], float(imod)/(100/stepFactor));
    }

    for (int i = 100; i < 200; i++) {
      int imod = int(i / stepFactor);
      heightColors[i] = lerpColor(heightColors[100], heightColors[200], float(imod-(100/stepFactor))/(100/stepFactor));
    }

    for (int i = 200; i < 300; i++) {
      int imod = int(i / stepFactor);
      heightColors[i] = lerpColor(heightColors[200], heightColors[300], float(imod-(200/stepFactor))/(100/stepFactor));
    }

    for (int i = 300; i < 400; i++) {
      int imod = int(i / stepFactor);
      heightColors[i] = lerpColor(heightColors[300], heightColors[400], float(imod-(300/stepFactor))/(100/stepFactor));
    }

    for (int i = 400; i < 500; i++) {
      int imod = int(i / stepFactor);
      heightColors[i] = lerpColor(heightColors[400], heightColors[500], float(imod-(400/stepFactor))/(100/stepFactor));
    }
  }
}

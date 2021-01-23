class MapManager {
  int[][] terrainHeight;
  boolean[][] changeOccured;

  final color[] heightColors = new color[501];
  final color lineColor = color(0,0,0, 70);

  int brushRadius = 50;
  int brushRadiusCache = brushRadius;
  int brushIntensity = 20;
  int brushIntensityCache = brushIntensity;
    
  float[][] brushPixels;
  int[][] brushPixelsWithIntensity;
  
  Tool tool = Tool.RAISE_TERRAIN;
    
  MapManager() {  
    initTerrainHeight();
    initHeightColors();
    calcBrush(brushRadius);
  }
  
  void drawToMapImage() {
    mapImage.beginDraw();
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
  
  void drawRingImage() {
    ringImage.beginDraw();
    ringImage.clear();
    
    for (int row = 1; row < height; row++) {
      for (int col = 1; col < width; col++) {        
        
        int sum = terrainHeight[row][col] > 300 ? 1 : 0;
        sum += terrainHeight[row-1][col] > 300 ? 1 : 0;
        sum += terrainHeight[row][col-1] > 300 ? 1 : 0;
        sum += terrainHeight[row-1][col-1] > 300 ? 1 : 0;

        if (sum > 0 && sum < 4) {
          ringImage.stroke(lineColor);
          ringImage.point(col, row);  
        }
        
        sum = terrainHeight[row][col] > 350 ? 1 : 0;
        sum += terrainHeight[row-1][col] > 350 ? 1 : 0;
        sum += terrainHeight[row][col-1] > 350 ? 1 : 0;
        sum += terrainHeight[row-1][col-1] > 350 ? 1 : 0;

        if (sum > 0 && sum < 4) {
          ringImage.stroke(lineColor);
          ringImage.point(col, row);  
        }
        
        sum = terrainHeight[row][col] > 400 ? 1 : 0;
        sum += terrainHeight[row-1][col] > 400 ? 1 : 0;
        sum += terrainHeight[row][col-1] > 400 ? 1 : 0;
        sum += terrainHeight[row-1][col-1] > 400 ? 1 : 0;

        if (sum > 0 && sum < 4) {
          ringImage.stroke(lineColor);
          ringImage.point(col, row);  
        }
        
        sum = terrainHeight[row][col] > 450 ? 1 : 0;
        sum += terrainHeight[row-1][col] > 450 ? 1 : 0;
        sum += terrainHeight[row][col-1] > 450 ? 1 : 0;
        sum += terrainHeight[row-1][col-1] > 450 ? 1 : 0;

        if (sum > 0 && sum < 4) {
          ringImage.stroke(lineColor);
          ringImage.point(col, row);  
        }
      }
    }
    ringImage.endDraw();
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
      
      for (int row = 0; row < brushPixels.length; row++) {
        for (int col = 0; col < brushPixels[0].length; col++) {
        
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
      
      mapImage.beginDraw();
      for (int row = 0; row < brushPixels.length; row++) {
        for (int col = 0; col < brushPixels[0].length; col++) {
        
          int colCorrected = col + toolX - brushRadius;
          int rowCorrected = row + toolY - brushRadius;
          
          if (colCorrected > 0 && rowCorrected > 0 && colCorrected < width && rowCorrected < height) {
            changePoint(colCorrected, rowCorrected, terrainHeightCopy[rowCorrected][colCorrected]); 
          }
        }
      }
      mapImage.endDraw();
    
    } else if (tool == Tool.RAISE_TERRAIN || tool == Tool.LOWER_TERRAIN) {
      
      mapImage.beginDraw();
      for (int row = 0; row < brushPixels.length; row++) {
        for (int col = 0; col < brushPixels[0].length; col++) {
        
          int colCorrected = col + toolX - brushRadius;
          int rowCorrected = row + toolY - brushRadius;
          
          if (colCorrected > 0 && rowCorrected > 0 && colCorrected < width && rowCorrected < height) {
            if (tool == Tool.RAISE_TERRAIN) {
                changePoint(colCorrected, rowCorrected, constrain(terrainHeight[rowCorrected][colCorrected] + brushPixelsWithIntensity[row][col], 0, 500));
            } else if (tool == Tool.LOWER_TERRAIN) {
                changePoint(colCorrected, rowCorrected, constrain(terrainHeight[rowCorrected][colCorrected] - brushPixelsWithIntensity[row][col], 0, 500));
            }
          }
        } 
      }
      mapImage.endDraw();
    }
  }
  
  void changeTool (Tool newTool) {
      tool = newTool;
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
          brushPixelsWithIntensity[row][col] = round(brushPixels[row][col] * brushIntensity); 
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
        brushPixelsWithIntensity[row][col] = round(brushPixels[row][col] * brushIntensity);
      } 
    } 
  }
  
  void changePoint (int col, int row, int newValue) {
    terrainHeight[row][col] = newValue;
    changeOccured[row][col] = true; 
    mapImage.stroke(heightColors[newValue]);
    mapImage.point(col, row);  
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
    
    int stepFactor = 20;
    
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

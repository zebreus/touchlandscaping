class MapManager {
  int[][] terrainHeight;
  boolean[][] changeOccured;

  final color[] heightColors = new color[501];
  final color lineColor = color(0,0,0, 70);

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

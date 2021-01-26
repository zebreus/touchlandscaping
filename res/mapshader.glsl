#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;
uniform vec2 texOffset;

uniform int steps;
uniform int shadingIntensity;
uniform float lineIntensity;
uniform sampler2D colorTexture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

bool isLine() {
  vec2 tcTop = vertTexCoord.st + vec2(0.0, -texOffset.t);
  vec2 tcLeft = vertTexCoord.st + vec2(-texOffset.s, 0.0);
  vec2 tc = vertTexCoord.st;
  
  int heightLeft = int(texture(texture, tcLeft).g * steps) ;
  int heightTop = int(texture(texture, tcTop).g * steps);
  int height = int(texture(texture, tc).g * steps);
  
  return (heightLeft != height || heightTop != height);
}

float shadingFactor(){
  return 0.0;
}

void main(void) {
  
  vec2 tc0 = vertTexCoord.st + vec2(-texOffset.s, -texOffset.t);
  vec2 tc1 = vertTexCoord.st + vec2(         0.0, -texOffset.t);
  vec2 tc2 = vertTexCoord.st + vec2(+texOffset.s, -texOffset.t);
  vec2 tc3 = vertTexCoord.st + vec2(-texOffset.s,          0.0);
  vec2 tc4 = vertTexCoord.st + vec2(         0.0,          0.0);
  vec2 tc5 = vertTexCoord.st + vec2(+texOffset.s,          0.0);
  vec2 tc6 = vertTexCoord.st + vec2(-texOffset.s, +texOffset.t);
  vec2 tc7 = vertTexCoord.st + vec2(         0.0, +texOffset.t);
  vec2 tc8 = vertTexCoord.st + vec2(+texOffset.s, +texOffset.t);
  
  float col0 = texture2D(texture, tc0).g;
  float col1 = texture2D(texture, tc1).g;
  float col2 = texture2D(texture, tc2).g;
  float col3 = texture2D(texture, tc3).g;
  float col4 = texture2D(texture, tc4).g;
  float col5 = texture2D(texture, tc5).g;
  float col6 = texture2D(texture, tc6).g;
  float col7 = texture2D(texture, tc7).g;
  float col8 = texture2D(texture, tc8).g;
  
  //Seems to llok nicer with 0.9 instead of 1.0
  float light = (((col1-col7) + (col5-col3) )*shadingIntensity)+0.9 ;
  
  float height = texture2D(texture, vertTexCoord.st).g;
  float pos = float(int(height*steps))/float(steps);
  vec4 color = texture(colorTexture, vec2(pos, 0)) ;
  
  if(isLine()){
    color = color * vec4(lineIntensity,lineIntensity,lineIntensity,1);
  }else{
    color = color * vec4(light,light,light,1);
  }
  
  gl_FragColor = color;
  
}

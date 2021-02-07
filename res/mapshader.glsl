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
  
  vec2 tc33 = vertTexCoord.st + vec2(-texOffset.s*2,          0.0);
  vec2 tc55 = vertTexCoord.st + vec2(+texOffset.s*2,          0.0);
  vec2 tc11 = vertTexCoord.st + vec2(         0.0, -texOffset.t*2);
  vec2 tc77 = vertTexCoord.st + vec2(         0.0, +texOffset.t*2);
  
  vec2 tc333 = vertTexCoord.st + vec2(-texOffset.s*4,          0.0);
  vec2 tc555 = vertTexCoord.st + vec2(+texOffset.s*4,          0.0);
  vec2 tc111 = vertTexCoord.st + vec2(         0.0, -texOffset.t*4);
  vec2 tc777 = vertTexCoord.st + vec2(         0.0, +texOffset.t*4);
  
  vec2 tc3333 = vertTexCoord.st + vec2(-texOffset.s*8,          0.0);
  vec2 tc5555 = vertTexCoord.st + vec2(+texOffset.s*8,          0.0);
  vec2 tc1111 = vertTexCoord.st + vec2(         0.0, -texOffset.t*8);
  vec2 tc7777 = vertTexCoord.st + vec2(         0.0, +texOffset.t*8);
  
  float col0 = texture2D(texture, tc0).g;
  float col1 = texture2D(texture, tc1).g;
  float col2 = texture2D(texture, tc2).g;
  float col3 = texture2D(texture, tc3).g;
  float col4 = texture2D(texture, tc4).g;
  float col5 = texture2D(texture, tc5).g;
  float col6 = texture2D(texture, tc6).g;
  float col7 = texture2D(texture, tc7).g;
  float col8 = texture2D(texture, tc8).g;
  float col33 = texture2D(texture, tc33).g;
  float col55 = texture2D(texture, tc55).g;
  float col11 = texture2D(texture, tc11).g;
  float col77 = texture2D(texture, tc77).g;
  float col333 = texture2D(texture, tc333).g;
  float col555 = texture2D(texture, tc555).g;
  float col111 = texture2D(texture, tc111).g;
  float col777 = texture2D(texture, tc777).g;
  float col3333 = texture2D(texture, tc3333).g;
  float col5555 = texture2D(texture, tc5555).g;
  float col1111 = texture2D(texture, tc1111).g;
  float col7777 = texture2D(texture, tc7777).g;
  
  // Calculate the shading. This is really hacky, but works quite well.
  float light = (((col7-col1+col5-col3)*1 + (col77-col11+col55-col33)*0.5 + (col777-col111+col555-col333)*0.25 + (col7777-col1111+col5555-col3333)*0.125 )*shadingIntensity) ;

  if(light < 0.0){
    light *= 2;
  }else{
    light /= 2;
  }
  ++light;
  
  float height = texture2D(texture, vertTexCoord.st).g;
  float pos = float(int(height*steps))/float(steps);
  vec4 color = texture(colorTexture, vec2(pos, 0)) ;
  
  color = color * vec4(light,light,light,1);
  if(isLine()){
    color = color * vec4(lineIntensity,lineIntensity,lineIntensity,1);
  }
  
  gl_FragColor = color;
  
}

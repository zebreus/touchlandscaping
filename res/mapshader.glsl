#ifdef GL_ES
precision highp float;
precision highp int;
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

float getHeight(const vec2 position){
    vec4 color = texture(texture, position);
    return (color.b/4)+(color.g*64);
}

bool isLine() {
  vec2 tcTop = vertTexCoord.st + vec2(0.0, -texOffset.t);
  vec2 tcLeft = vertTexCoord.st + vec2(-texOffset.s, 0.0);
  vec2 tc = vertTexCoord.st;
  
  int heightLeft = int(getHeight( tcLeft) * steps) ;
  int heightTop = int(getHeight( tcTop) * steps);
  int height = int(getHeight( tc) * steps);
  
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
  
  float col0 = getHeight(tc0);
  float col1 = getHeight(tc1);
  float col2 = getHeight(tc2);
  float col3 = getHeight(tc3);
  float col4 = getHeight(tc4);
  float col5 = getHeight(tc5);
  float col6 = getHeight(tc6);
  float col7 = getHeight(tc7);
  float col8 = getHeight(tc8);
  float col33 = getHeight(tc33);
  float col55 = getHeight(tc55);
  float col11 = getHeight(tc11);
  float col77 = getHeight(tc77);
  float col333 = getHeight(tc333);
  float col555 = getHeight(tc555);
  float col111 = getHeight(tc111);
  float col777 = getHeight(tc777);
  float col3333 = getHeight(tc3333);
  float col5555 = getHeight(tc5555);
  float col1111 = getHeight(tc1111);
  float col7777 = getHeight(tc7777);
  
  // Calculate the shading. This is really hacky, but works quite well.
  float light = (((col7-col1+col5-col3)*1 + (col77-col11+col55-col33)*0.5 + (col777-col111+col555-col333)*0.25 + (col7777-col1111+col5555-col3333)*0.125 )*shadingIntensity) ;

  if(light < 0.0){
    light *= 2;
  }else{
    light /= 2;
  }
  ++light;
  
  float height = getHeight(vertTexCoord.st);
  float pos = float(int(height*steps))/float(steps);
  vec4 color = texture(colorTexture, vec2(pos, 0)) ;
  
  color = color * vec4(light,light,light,1);
  if(isLine()){
    color = color * vec4(lineIntensity,lineIntensity,lineIntensity,1);
  }
  
  gl_FragColor = color;
  
}

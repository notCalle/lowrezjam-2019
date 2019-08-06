precision highp float;
uniform mat4 MV;
uniform mat4 P;
attribute vec3 vert;
attribute vec3 normal;
attribute vec4 color;
varying vec4 v_color;
varying vec3 v_pos;
varying vec3 v_normal;
void main() {
  v_pos = vert;
  v_color = color;
  v_normal = normal;
  gl_Position = P * MV * vec4(vert, 1);
}

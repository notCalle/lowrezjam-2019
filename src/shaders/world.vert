precision highp float;

uniform mat4 MV;
uniform mat4 P;
uniform vec3 camera;
attribute vec3 vert;
attribute vec3 normal;
attribute vec3 color;
attribute vec2 phong;

varying vec3 v_color;
varying vec2 v_phong;
varying vec3 v_pos;
varying vec3 v_normal;
varying vec3 v_camera;
varying float v_y;
varying float v_dist;

void main() {
	vec4 v = MV * vec4(vert, 1);
	vec4 n = MV * vec4(normal, 0);
	vec4 c = MV * vec4(camera, 1);

  v_color = color;
  v_phong = phong;
  v_pos = v.xyz;
  v_normal = normalize(n.xyz);
  v_camera = normalize((c - v).xyz);
  v_dist = distance(c, v);
  v_y = vert.y;

  gl_Position = P * v;
}

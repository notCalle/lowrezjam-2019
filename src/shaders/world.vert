precision highp float;

uniform mat4 MV;
uniform mat4 P;
uniform vec3 camera;
attribute vec3 vert;
attribute vec3 normal;
attribute vec4 color;
attribute float shininess;

varying vec4 v_color;
varying float v_shininess;
varying vec3 v_pos;
varying vec3 v_surface;
varying vec3 v_normal;
varying vec3 v_camera;
varying float v_y;
varying float v_dist;

void main() {
	vec4 v = MV * vec4(vert, 1);
	vec4 n = MV * vec4(normal, 0);
	vec4 c = MV * vec4(camera, 1);
  vec4 s = MV * vec4(vert.x, 0, vert.z, 1);

  v_color = color;
  v_shininess = shininess;
  v_pos = v.xyz;
  v_surface = s.xyz;
  v_normal = normalize(n.xyz);
  v_camera = c.xyz;
  v_y = vert.y;

  gl_Position = P * v;
}

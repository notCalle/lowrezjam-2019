precision mediump float;
uniform mat4 MV;
uniform vec3 camera;
uniform vec3 light;
uniform vec4 light_color;
uniform float far;
varying vec4 v_color;
varying vec3 v_pos;
varying vec3 v_normal;
void main() {
  float dist = distance(v_pos, camera);
  float dist_a = pow(clamp(dist/far, 0.0, 1.0), 2.0);
  vec3 l = normalize((MV * vec4(light, 0.0)).xyz);
  vec3 nm = normalize((MV * vec4(v_normal, 0.0)).xyz);
  // Diffuse light, v_color.a is used to mix ambient vs direct light
  vec4 c = mix(vec4(0), v_color, v_color.a + (1.0-v_color.a) * dot(nm,l));

  if (v_pos.y <= 0.0) {
    c = mix(mix(c, vec4(0,0,0,1),
                           -v_pos.y/3.),
                       vec4(.1,.3,.5,1), 0.6);
  }
  gl_FragColor = vec4(c.rgb, 1.0-dist_a) * light_color;
}

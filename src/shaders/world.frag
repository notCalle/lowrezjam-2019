precision mediump float;

uniform mat4 MV;
uniform vec3 light;
uniform vec4 light_color;
uniform float far;

varying vec3 v_color;
varying vec3 v_pos;
varying vec3 v_normal;
varying vec3 v_camera;
varying float v_y;
varying float v_dist;
varying vec2 v_phong; //(shininess, power)

// light color alpha channel is used for ambient to direct light mix
vec3 shade(vec4 light, vec4 l_color) {
  vec4 water_color = vec4(0.1,0.3,0.5,0.6);
  vec3 light_v = normalize((light.w == 0.0) ? light.xyz : (light.xyz - v_pos));
  vec3 halfway_v = normalize(light_v + v_camera);
  vec3 diffuse = mix(vec3(0), v_color.rgb,
                     l_color.a + (1.0-l_color.a)*dot(v_normal,light_v));
  // blinn-phong specular reflection
  float spec = v_phong.t*pow(clamp(dot(v_normal,halfway_v), 0.0, 1.0), v_phong.s);

  if (v_y <= 0.0) {
    diffuse = mix(mix(diffuse, vec3(0,0,0), -v_y/3.), water_color.rgb, water_color.a);
    spec = 0.0;
  }
  return (diffuse+vec3(spec))*l_color.rgb;
}

void main() {
  float dist_a = pow(clamp(v_dist/far, 0.0, 1.0), 2.0);
  vec3 c = shade(MV * vec4(light,0), light_color);

  gl_FragColor = vec4(c, 1.0-dist_a);
}

precision mediump float;

uniform mat4 MV;
uniform vec3 sun_v;
uniform vec4 sun_c;
uniform vec3 moon_v;
uniform vec4 moon_c;
uniform float far;
uniform vec4 torch_color;

varying vec4 v_color;
varying float v_shininess;
varying vec3 v_pos;
varying vec3 v_surface;
varying vec3 v_normal;
varying vec3 v_camera;
varying float v_y;
varying float v_dist;

const float pi = 3.14159;
const float diff_coef = 1.0/pi; // energy conservation coefficient
const float w_shininess = 16.0;

// light color alpha channel is used for ambient to direct light mix
vec3 shade(vec4 light, vec4 l_color) {
  vec3 camera_v = normalize(v_camera - v_pos);
  vec3 light_v = normalize((light.w == 0.0) ? light.xyz : (light.xyz - v_pos));
  float diffuseness = v_color.a;

  // diffuse reflection
  float diff = mix(max(dot(v_normal, light_v), 0.0), 1.0, l_color.a);
  vec3 diff_color = diff_coef * diff * v_color.rgb;

  // blinn-phong specular reflection, only used for water at the moment
  vec3 halfway_v = normalize(light_v + camera_v);
  float spec_coef = (v_shininess + 8.0)/(8.0 + pi);
  float spec = 0.0; // FIXME: specular is broken, idk why
  //float spec = pow(max(dot(v_normal,halfway_v), 0.0), v_shininess)*spec_coef;

  // Pretty messy water shading approximation
  if (v_y <= 0.0) {
    float w_spec_coef = (w_shininess + 8.0)/(8.0 + pi);
    vec4 water_color = vec4(0.4,0.6,0.9,0.5);
    vec3 w_normal = (MV*vec4(0,1,0,0)).xyz;
    vec3 w_camera = normalize(v_camera - v_surface);
    float w_diff = mix(max(dot(w_normal, light_v), 0.0), 1.0, l_color.a);
    vec3 w_diff_color = diff_coef * w_diff * water_color.rgb;
    float fr = pow(distance(v_camera, v_surface)/far, 2.0);

    diffuseness = 0.9;

    diff_color = mix(diff_color, vec3(0.0), -v_y/3.0);
    diff_color = mix(diff_color, w_diff_color, water_color.a);

    vec3 halfway_w = normalize(light_v + w_camera);
    spec = pow(max(dot(w_normal,halfway_w), 0.0), w_shininess)*w_spec_coef;
  }

  return mix(vec3(spec), diff_color, diffuseness)*l_color.rgb;
}

void main() {
  float dist = distance(v_camera, v_pos);
  float dist_a = pow(clamp(dist/far, 0.0, 1.0), 2.0);
  vec3 c = shade(MV * vec4(sun_v,0), sun_c)
         + shade(MV * vec4(moon_v,0), moon_c)
         + shade(vec4(v_camera,1), torch_color/(1.0+dist));

  gl_FragColor = vec4(pow(c,vec3(1.0/2.2)), 1.0-dist_a);
}

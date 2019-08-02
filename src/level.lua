--- Game level

local level = ...
local fonts = require'fonts'
local camera = am.lookat(vec3(0,1.1,0),vec3(0,1,-1),vec3(0,1,0))
local objects = (function()
  local r=50
  local y=5
  return am.bind{
    pos = am.vec3_array{
        -r, y, r,
        r, y, r,
        -r, -y, -r,
        r, -y, -r},
    color = am.vec3_array{
        0, 0, 0,
        1, 0, 1,
        0, 1, 0,
        .5, .5, .5},
  }^am.draw("triangles", am.ushort_elem_array{1, 2, 3, 2, 4, 3})
end)()


local function shader()
  local vert = [[
    precision highp float;
    uniform mat4 MV;
    uniform mat4 P;
    attribute vec3 pos;
    attribute vec3 color;
    varying vec3 v_color;
    void main() {
        v_color = color;
        gl_Position = P * MV * vec4(pos, 1);
    }
  ]]
  local frag = [[
    precision mediump float;
    varying vec3 v_color;
    void main() {
        gl_FragColor = vec4(v_color, 1.0);
    }
  ]]
  return am.program(vert,frag)
end

local function update_camera()
  local dir = camera.center

  dir = (math.rotate4(5*math.rad(am.delta_time),vec3(0,1,0)) * vec4(dir,0)).xyz
  camera.center = dir
end

function level:init(lowrez, window)
  local background = am.cull_face'back'^am.use_program(shader())^am.bind{
    P = math.perspective(math.rad(60),1,0.1,100)
  }^camera^objects


  local foreground = am.blend'add_alpha'^am.text'Hello'

  local scene = background^foreground

  scene:action(function()
    if window:key_pressed'escape' then
      lowrez:load'hello'
    end
    update_camera()
  end)

  return scene
end

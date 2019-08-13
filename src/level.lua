--- Game level
local level = ...
table.merge(level,{
  __index = level
})
local fonts = require'fonts'
local map = require'map'
local player = require'player'
local far = 64
local tau = math.atan(1)*8

function level:update_camera()
  local pos, dir = self.player:eye()
  self.camera.eye = pos
  self.camera.center = pos + dir
end

local rot_axis = math.normalize(vec3(0,-1,1))

local function sun_light(time)
  local r = time/30
  local s = math.cos(r)
  local v = vec3(0,1,1)*quat(-r,rot_axis)
  if s > 0 then
    return v, math.mix(vec4(0.6,0.3,0.2,.25),vec4(1.5,1.5,1.5,.35),s)
  else
    return v, math.mix(vec4(0.6,0.3,0.2,.25),vec4(0,0,0,1),-s)
  end
end

local function moon_light(time)
  local r = time/30
  local s = math.cos(r)
  local v = vec3(0,-1,-1)*quat(-r,rot_axis)
  if s > 0 then
    return v, math.mix(vec4(0.2,0.1,0.1,.25),vec4(0,0,0,1),s)
  else
    return v, math.mix(vec4(0.2,0.1,0.1,.25),vec4(0.3,0.3,0.6,.35),-s)
  end
end

function level:init(lowrez, window)
  local self = setmetatable({}, self)
  lowrez.depth_buffer = true
  window.lock_pointer = true

  local camera = am.lookat(vec3(0,1,0),vec3(0,1,-1),vec3(0,1,0))
  self.camera = camera
  self.window = window
  self.map = map:new(camera, far)
  local ground = self.map.node
  local background = am.bind{
    P = math.perspective(math.rad(45),1,0.001,far),
    sun_v = vec3(0.5,1,1),
    sun_c = vec4(1,1,1,0.25),
    moon_v = vec3(-0.5,-1,-1),
    moon_c = vec4(0,0,0,0.35),
    torch_color = vec4(0.0),
  }^camera^ground

  local foreground = am.blend'alpha'
  ^am.depth_test'always'
  ^am.group {
    am.translate(vec2(-41,41))
    ^am.text(fonts['little-conquest8'],
             'Hello, LowRez!',vec4(1,.75,.5,0.8),
             'left','top')
    ,
    am.translate(vec2(23.5,23.5))
    ^am.group{
      am.circle(vec2(0,0),7.5,vec4(.2,.2,.2,.7))
      ,
      am.rotate(0):tag'compass'
      ^am.group{
        am.line(vec2(-1,0),vec2(0,7.5),1,vec4(.7,0,0,1)),
        am.line(vec2(0,0),vec2(0,4.5),1,vec4(.7,0,0,1)),
        am.line(vec2(1,0),vec2(0,7.5),1,vec4(.7,0,0,1)),

        am.line(vec2(-1,0),vec2(0,-7.5),1,vec4(.7,.7,.7,1)),
        am.line(vec2(0,0),vec2(0,-4.5),1,vec4(.7,.7,.7,1)),
        am.line(vec2(1,0),vec2(0,-7.5),1,vec4(.7,.7,.7,1)),
      }
    }
    ,
    am.translate(vec2(-23,-25))
    ^am.group{
      am.rect(-2,0,2,30,vec4(0.3,0.15,0,1))
      ,
      am.particles2d{
        source_pos = vec2(0,28),
        source_pos_var = vec2(2,2),
        max_particles = 200,
        emission_rate = 100,
        start_size = 2.0,
        start_size_var = 1.0,
        end_size = 0.5,
        end_size_var = 0.5,
        life = 2,
        life_var = 0.5,
        angle = tau/4,
        angle_var = tau/8,
        speed = 5,
        speed_var = 1,
        start_color = vec4(1.0,0.7,0.0,0.7),
        start_color_var = vec4(0.1,0.1,0.0,0.1),
        end_color = vec4(0.5,0.2,0.0,0.7),
        end_color_var = vec4(0.1,0.1,0.0,0.1),
        gravity = vec2(0,10),
      }
    }:tag'torch'
  }

  self.scene = am.group{
    background,
    foreground
  }

  self.player = player:load()(self)
  self:update_camera()
  self.map:regenerate()

  self.scene:action(function()
    local sky_color = vec4(0.3, 0.5, 0.7, 1)
    local sun_v, sun_c = sun_light(am.frame_time)
    local moon_v, moon_c = moon_light(am.frame_time)

    self.player:update()
    self:update_camera()
    self.map:update()
    foreground'text'.text = table.tostring(window:keys_down())
    foreground'compass'.rotation = quat(self.player.heading)
    foreground'torch'.hidden = self.player.torch == 0.0

    background.torch_color = (vec4(0.5,0.3,0.1,0.9) + math.randvec4()*0.1)
                           * self.player.torch
    background.sun_v = sun_v
    background.sun_c = sun_c
    background.moon_v = moon_v
    background.moon_c = moon_c
    window.clear_color = sky_color * (sun_c + moon_c)
    if window:key_pressed'escape' then
      self.player:save()
      lowrez:load'hello'
    end
  end)

  return self.scene
end

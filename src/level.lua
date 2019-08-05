--- Game level
local level = ...
table.merge(level,{
  __index = level
})
local fonts = require'fonts'
local map = require'map'
local player = require'player'
local far = 64

function level:update_camera()
  local pos, dir = self.player:eye()
  self.camera.eye = pos
  self.camera.center = pos + dir
end

local function lighting(time)
  local s = math.cos(time/30)
  if s > 0 then
    return math.mix(vec4(0.7,0.5,0.3,1),vec4(1),s)
  else
    return math.mix(vec4(0.7,0.5,0.3,1),vec4(0.4,0.4,0.5,1),-s)
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
    light = vec3(0.5,1,1),
    light_color = vec4(1,1,1,1),
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
  }

  self.scene = am.group{
    background, foreground
  }

  self.player = player:load()(self)
  self:update_camera()
  self.map:regenerate()

  self.scene:action(function()
    local sky_color = vec4(0.3, 0.5, 0.7, 1)
    local light_color = lighting(am.frame_time)
    self.player:update()
    self:update_camera()
    self.map:update()
    foreground'text'.text = table.tostring(window:keys_down())
    foreground'compass'.rotation = quat(self.player.heading)
    background.light_color = light_color
    window.clear_color = sky_color * light_color
    if window:key_pressed'escape' then
      self.player:save()
      lowrez:load'hello'
    end
  end)

  return self.scene
end

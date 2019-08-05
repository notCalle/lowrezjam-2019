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

function level:init(lowrez, window)
  local self = setmetatable({}, self)
  lowrez.depth_buffer = true

  local camera = am.lookat(vec3(0,1,0),vec3(0,1,-1),vec3(0,1,0))
  self.camera = camera
  self.window = window
  self.map = map:new(camera, far)
  local ground = self.map.node

  local background = am.bind{
    P = math.perspective(math.rad(45),1,0.001,far),
    light = vec3(0.5,1,1),
    sky_color = lowrez.clear_color,
  }^camera^ground

  ground:action(function()
    ground:update()
  end)

  local foreground = am.blend'alpha'
  ^am.depth_test'always'
  ^am.group {
    am.translate(vec2(0,28))
    ^am.text(fonts['little-conquest8'],
             'Hello, LowRez!',vec4(1,.75,.5,0.8))
    ,
    am.translate(vec2(23.5,23.5))
    ^am.group{
      am.circle(vec2(0,0),7.5,vec4(.2,.2,.2,.7))
      ,
      am.rotate(0):tag'compass'
      ^am.rect(-0.5,4.5,0.5,7.5,vec4(1,0,0,.7))
    }
  }

  self.scene = am.group{
    background, foreground
  }

  self.player = player:load()(self)
  self:update_camera()
  self.map:regenerate()

  self.scene:action(function()
    self.player:update()
    self:update_camera()
    self.map:update()
    foreground'text'.text = table.tostring(window:keys_down())
    foreground'compass'.rotation = quat(self.player.heading)

    if window:key_pressed'escape' then
      self.player:save()
      lowrez:load'hello'
    end
  end)

  return self.scene
end

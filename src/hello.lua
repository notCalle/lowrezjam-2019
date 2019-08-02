local hello = ...
local fonts = require'fonts'
local sprites = require'sprites'

function hello:init(lowrez)
  local window = lowrez:window()

  local scene = am.group{
    am.circle(vec2(0,0), 32, vec4(0,.5,0,1))
    ,
    am.rotate(0):action(function(node)
      if not window:mouse_down'left' then
        node.angle = node.angle + 0.5 * am.delta_time
      end
    end)
    ^ am.text(fonts['little-conquest8'],"Hello,\nLowRez!")
    ,
    am.rotate(0):action(function(node)
      node.angle = - 1.0 * am.frame_time
    end)
    ^ am.translate(vec2(24,0))
    ^ am.sprite(sprites.Untitled)
  }

  scene:action(function()
    if window:key_pressed'escape' then
      window:close()
    end
  end)

  return scene
end

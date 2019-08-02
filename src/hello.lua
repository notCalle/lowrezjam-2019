local hello = ...
local fonts = require'fonts'

function hello:init(lowrez)
  local window = lowrez:window()

  hello.scene = {
    am.circle(vec2(0,0), 32, vec4(0,.5,0,1))
    ,
    am.rotate(0):action(function(node)
      if not window:mouse_down'left' then
        node.angle = node.angle + 0.5 * am.delta_time
      end
    end)
    ^ am.text(fonts['little-conquest8'],"Hello,\nLowRez!")
  }
end

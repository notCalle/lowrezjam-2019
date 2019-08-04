local hello = ...
local fonts = require'fonts'

function hello:init(lowrez)
  lowrez.depth_buffer = false

  local window = lowrez:window()
  local scene = am.group{
    am.blend'alpha'
    ^ am.text(fonts['little-conquest8'],
              "Hello, LowRez!\n\nPress space\nto start",
              vec4(1,.75,.5,0.9))
  }

  scene:action(function()
    if window:key_pressed'escape' then
      window.lock_pointer = false
      window:close()
    end
    if window:key_pressed'space' then
      lowrez:load'level'
    end
  end)

  return scene
end

noglobals()
local lowrez = require'lowrez':new{
  show_perf_stats = true,
  clear_color = vec4(.5,0,.5,1)
}
lowrez:window()

lowrez:load'hello'

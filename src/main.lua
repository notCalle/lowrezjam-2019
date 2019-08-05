noglobals()
local lowrez = require'lowrez':new{
  -- show_perf_stats = true,
}
lowrez:window{
    clear_color = vec4(0.3, 0.5, 0.7, 1),
}
lowrez:load'hello'

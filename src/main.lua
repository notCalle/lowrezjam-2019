noglobals()
local lowrez = require'lowrez':new{}
lowrez:window{
    clear_color = vec4(0.3, 0.5, 0.7, 1),
}
lowrez:load'hello'

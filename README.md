# amulet-lowrez
[Amulet] setup module for LowRez rendering

## usage
In your `main.lua` for an [Amulet] project:
```lua
local lowrez = require'lowrez':new{...}
```

`...` options are, with defaults:
- `show_perf_stats = false`      -- debug overlay
- `width = 64`                   -- lowrez 4K pixel display
- `height = 64`                  -- lowrez 4K pixel display
- `scale = 8`                    -- scale factor for initial window size
- `clear_color = vec4(0,0,0,1)`  -- display background color

Optionally, call `lowrez:window{...}` to configure `am.window` options for the
singleton window.

Activate your scene graph by calling `lowrez:activate{...}` with the contents
for an `am.group{...}` that will be rendered under the lowrez constraints.

`lowrez.scene` contains the root group with your scene graph.

You can pick tagged nodes from your graph by calling `lowrez'tag'`.

Calling `lowrez:load'name'` will `require` the module 'name', call its
`module:init` function if it exists, and then activate the scene graph
in `module.scene`.

[Amulet]: https://www.amulet.xyz

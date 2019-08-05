--- Amulet setup module for LowRez rendering
--
-- @see https://amulet.xyz
-- @module lowrez
-- @usage
-- > local lowrez = require'lowrez':new{...}
-- ... options are, with defaults:
-- show_perf_stats = false      -- debug overlay
-- width = 64                   -- lowrez 4K pixel display
-- height = 64                  -- lowrez 4K pixel display
-- scale = 8                    -- scale factor for initial window size
-- clear_color = vec4(0,0,0,1)  -- display background color
--
-- Optionally, call lowrez:window{...} to configure am.window options for the
-- singleton window.
--
-- Activate your scene graph by calling lowrez:activate{...} with the contents
-- for an am.group{...} that will be rendered under the lowrez constraints.
--
-- lowrez.scene contains the root group with your scene graph
--
-- You can pick tagged nodes from your graph by calling lowrez'tag'
--
-- lowrez:load'name' will require the module 'name', call its module:init
-- function if it exists, and then activate the scene graph in module.scene
--
-- @author Calle Englund &lt;calle@discord.bofh.se&gt;
-- @copyright &copy; 2019 Calle Englund
-- @license
-- The MIT License (MIT)
--
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be included
-- in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
-- OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local lowrez = ...
table.merge(lowrez, {
  __index = lowrez,
  width = 64,
  height = 64,
  scale = 8,
  clear_color = vec4(0,0,0,0)
})

--- Create a new lowrez configuration
function lowrez:new(...)
  return setmetatable(... or {}, self)
end

local _window
--- Create the singleton window
function lowrez:window(...)
  if _window then return _window end

  local opts = ... or {}
  table.merge(opts,{
    width = self.width * self.scale,
    height = self.height * self.scale
  })
  _window = am.window(opts)
  return _window
end

--- Load and activate a scene graph from a module
function lowrez:load(name)
  local module = require(name)

  if module.init then
    self:activate(module:init(self, self:window()))
  else
    self:activate(am.group(module))
  end

  return module
end

--- Activate a scene graph
function lowrez:activate(...)
  local window = self:window()

  self.scene = ...
  window.scene = am.blend'alpha'
               ^ am.postprocess(self)
               ^ am.scale(self.scale)
               ^ self.scene
  self.scene:action(function()
    if window:key_pressed'f12' then
      am.toggle_perf_overlay()
    end
  end)
end

function lowrez:__call(tag)
  return self.scene(tag)
end

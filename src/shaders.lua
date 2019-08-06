local shaders = ...
table.merge(shaders,{
  __index = shaders,
})
setmetatable(shaders,shaders)

--- Lazily load and compile shaders from files
function shaders:__index(name)
  local shader = rawget(self, name)
  if shader then return shader end

  local vert = am.load_string('shaders/'..name..'.vert')
  local frag = am.load_string('shaders/'..name..'.frag')
  shader = am.program(vert, frag)
  rawset(self, name, shader)
  return shader
end

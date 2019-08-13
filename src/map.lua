local shaders = require'shaders'
local map = ...
table.merge(map, {
  __index = map
})

local shader_struct = {
    "vert", "vec3",
    "normal", "vec3",
    "color", "vec4",
    "shininess", "float"
}

local function int2(v)
  local f = math.floor
  return vec2(f(v.x), f(v.y))
end

local function int3(v)
  local f = math.floor
  return vec3(f(v.x), f(v.y), f(v.z))
end

local function normal(v1, v2, v3)
  return math.normalize(math.cross(v2-v1, v3-v2))
end

local function memo(fn)
  -- weak value table
  local m = setmetatable({},{__mode="v"})

  return function(...)
    local k = tostring(...)
    local v = m[k]
    if not v then
      v = {fn(...)}
      m[k] = v
    end
    return unpack(v)
  end
end

local corner3 = memo(function(pos2)
  local soil = math.simplex(pos2/100)*3
  local rock = (math.simplex(-pos2/20)^3)*5
             + (math.simplex(pos2)^5)
             - (math.simplex(pos2/500)) * 7
  return vec3(pos2.x, math.max(rock, soil), pos2.y), rock, soil
end)

function map:get(pos2)
  pos2 = int2(pos2)
  local v01 = corner3(pos2 + vec2(-1,0))
  local v10 = corner3(pos2 + vec2(0,-1))
  local v11,rock,soil = corner3(pos2)
  local v12 = corner3(pos2 + vec2(0,1))
  local v21 = corner3(pos2 + vec2(1,0))

  return {
    vert = v11,

    norm = (normal(v01,v11,v10)
          + normal(v10,v11,v21)
          + normal(v21,v11,v12)
          + normal(v12,v11,v01)) / 4,

    material = rock > 6 and {     -- snowy montain tops
      color = vec4(1.3,1.4,1.5,1),
      phong = 0.0,
    } or rock >= soil-0.5 and {   -- mountains
      color = vec4(0.25,0.25,0.35,1),
      phong = 0.0,
    } or soil < 0.1 and {         -- sandy beaches
      color = vec4(0.25,0.25,0.15,1),
      phong = 0.0,
    } or {                        -- grassy plains
      color = vec4(0.15,0.25,0.10,1),
      phong = 0.0,
    }
  }
end

function map:interpolate(pos2)
    local xf = math.fract(pos2.x)
    local yf = math.fract(pos2.y)
    local posi = int2(pos2)
    local p00 = corner3(posi)
    local p01 = corner3(posi + vec2(0,1))
    local p10 = corner3(posi + vec2(1,0))
    local p11 = corner3(posi + vec2(1,1))
    return p00 * (1-xf)*(1-yf)
         + p01 * (1-xf)*yf
         + p10 * xf*(1-yf)
         + p11 * xf*yf
end

function map:update_chunk(pos2, verts, normals, colors, phongs)
  local far = self.far
  local size = far * 2 + 1
  local c = {}
  c[1] = map:get(pos2)
  c[2] = map:get(pos2 + vec2(0, 1))
  c[3] = map:get(pos2 + vec2(1, 1))
  c[4] = map:get(pos2 + vec2(1, 0))
  local c0vert = (c[1].vert + c[2].vert + c[3].vert + c[4].vert) / 4
  local c0color = (c[1].material.color
                 + c[2].material.color
                 + c[3].material.color
                 + c[4].material.color) / 4
  local c0phong = (c[1].material.phong
                 + c[2].material.phong
                 + c[3].material.phong
                 + c[4].material.phong) / 4
  local c0norm = (c[1].norm + c[2].norm + c[3].norm + c[4].norm) / 4
  local vts = {
    c0vert, c[1].vert, c[2].vert,
    c0vert, c[2].vert, c[3].vert,
    c0vert, c[3].vert, c[4].vert,
    c0vert, c[4].vert, c[1].vert,
  }
  local nms = {
    c0norm, c[1].norm, c[2].norm,
    c0norm, c[2].norm, c[3].norm,
    c0norm, c[3].norm, c[4].norm,
    c0norm, c[4].norm, c[1].norm,
  }
  local cols = {
    c0color, c[1].material.color, c[2].material.color,
    c0color, c[2].material.color, c[3].material.color,
    c0color, c[3].material.color, c[4].material.color,
    c0color, c[4].material.color, c[1].material.color,
  }
  local phos = {
    c0phong, c[1].material.phong, c[2].material.phong,
    c0phong, c[2].material.phong, c[3].material.phong,
    c0phong, c[3].material.phong, c[4].material.phong,
    c0phong, c[4].material.phong, c[1].material.phong,
  }
  local offset = (((pos2.x%size) * size) + pos2.y%size) * 12 + 1

  verts:set(vts, offset, 12)
  normals:set(nms, offset, 12)
  colors:set(cols, offset, 12)
  phongs:set(phos, offset, 12)
end

local function update_chunks(self)
  local far = self.far
  local size = far * 2 + 1
  local buffers = am.struct_array(size^2 * 12, shader_struct)
  local vert = buffers.vert
  local normal = buffers.normal
  local color = buffers.color
  local phong = buffers.shininess
  local t0 = os.clock()
  local eye2 = int3(self.camera.eye)
  local queue = self._chunk_queue
  local pull = table.remove
  local max_time = 1/90

  while true do
    local pos = pull(queue,1)
    local eye = eye2
    while pos do
      self:update_chunk(pos, vert, normal, color, phong)
      if os.clock()-t0 > max_time then
        coroutine.yield()
        t0 = os.clock()
      end
      pos = pull(queue,1)
    end
    self.bind.vert:set(vert)
    self.bind.normal:set(normal)
    self.bind.color:set(color)
    self.bind.shininess:set(phong)

    eye2 = int3(self.camera.eye)
    while eye == eye2 do
      coroutine.yield()
      t0 = os.clock()
      eye2 = int3(self.camera.eye)
    end

    if eye2.x > eye.x then
      self:enqueue_chunks(vec2(eye.x+far,eye2.z-far),
                          vec2(eye2.x+far,eye2.z+far))
    elseif eye2.x < eye.x then
      self:enqueue_chunks(vec2(eye2.x-far,eye2.z-far),
                          vec2(eye.x-far,eye2.z+far))
    end

    if eye2.z > eye.z then
      self:enqueue_chunks(vec2(eye2.x-far,eye.z+far),
                          vec2(eye2.x+far,eye2.z+far))
    elseif eye2.z < eye.z then
      self:enqueue_chunks(vec2(eye2.x-far,eye2.z-far),
                          vec2(eye2.x+far,eye.z-far))
    end
  end
end

function map:enqueue_chunks(c1,c2)
  -- log(''..c1..'->'..c2)
  for x = c1.x,c2.x do
    for y = c1.y,c2.y do
      table.insert(self._chunk_queue,vec2(x,y))
    end
  end
end

function map:update()
  self:update_chunks()
  self.bind.camera = self.camera.eye
end

function map:regenerate()
  local eye = int3(self.camera.eye)
  local far = self.far
  self._chunk_queue = {}
  self:enqueue_chunks(vec2(eye.x-far,eye.z-far), vec2(eye.x+far,eye.z+far))
  self:update_chunks(true)
end

function map:new(camera, far)
  local self = setmetatable({}, self)
  local size = far * 2 + 1
  local binds = am.struct_array(size^2 * 12, shader_struct)
  binds.camera = camera.eye
  binds.far = far-1
  self.bind = am.bind(binds)
  self.camera = camera
  self.far = far
  self.update_chunks = coroutine.wrap(update_chunks)
  self._chunk_queue = {}

  self.node = am.group{
    self.bind
    ^am.cull_face'back'
    ^am.use_program(shaders.world)
    ^am.draw'triangles'
  }
  return self
end

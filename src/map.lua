local map = ...
table.merge(map, {
  __index = map
})

local function int3(v)
  local f = math.floor
  return vec3(f(v.x), f(v.y), f(v.z))
end

local function memo(fn)
  -- weak value table
  local m = setmetatable({},{__mode="v"})

  return function(...)
    local k = tostring(...)
    local v = m[k]
    if not v then
      v = fn(...)
      m[k] = v
    end
    return v
  end
end

local corner3 = memo(function(pos2)
  local soil = math.simplex(pos2/100)*3
  local rock = (math.simplex(-pos2/20)^3)*5
             + (math.simplex(pos2)^5)
             - (math.simplex(pos2/500)) * 7
  local color =
    rock > 6 and vec4(1.0,1.0,1.0,0.75)
    or rock >= soil-0.5 and vec4(0.5,0.5,0.5,0.5)
    or soil < 0.1 and vec4(0.7,0.7,0.5,0.35)
    or vec4(0.1,0.5,0.2,0.45)

  return {
    vert = vec3(pos2.x, math.max(rock, soil), pos2.y),
    color = color
  }
end)

function map:get(pos2)
  return corner3(pos2{
    x = math.floor(pos2.x),
    y = math.floor(pos2.y)
  })
end

function map:interpolate(pos2)
    local xf = math.fract(pos2.x)
    local yf = math.fract(pos2.y)
    local posi = vec2(math.floor(pos2.x),math.floor(pos2.y))
    local p00 = map:get(posi).vert
    local p01 = map:get(posi + vec2(0,1)).vert
    local p10 = map:get(posi + vec2(1,0)).vert
    local p11 = map:get(posi + vec2(1,1)).vert
    return p00 * (1-xf)*(1-yf)
         + p01 * (1-xf)*yf
         + p10 * xf*(1-yf)
         + p11 * xf*yf
end

local function normal(v1, v2, v3)
  return math.cross(v2-v1, v3-v2)
end

function map:update_chunk(pos2, verts, normals, colors)
  local far = self.far
  local size = far * 2 + 1
  local c = {}
  c[1] = map:get(pos2)
  c[2] = map:get(pos2 + vec2(0, 1))
  c[3] = map:get(pos2 + vec2(1, 1))
  c[4] = map:get(pos2 + vec2(1, 0))
  local c0vert = (c[1].vert + c[2].vert + c[3].vert + c[4].vert) / 4
  local c0color = (c[1].color + c[2].color + c[3].color + c[4].color) / 4
  local vts = {
    c0vert, c[1].vert, c[2].vert,
    c0vert, c[2].vert, c[3].vert,
    c0vert, c[3].vert, c[4].vert,
    c0vert, c[4].vert, c[1].vert,
  }
  local nms = {
    normal(c0vert, c[1].vert, c[2].vert),
    normal(c[1].vert, c[2].vert, c0vert),
    normal(c[2].vert, c0vert, c[1].vert),

    normal(c0vert, c[2].vert, c[3].vert),
    normal(c[2].vert, c[3].vert, c0vert),
    normal(c[3].vert, c0vert, c[2].vert),

    normal(c0vert, c[3].vert, c[4].vert),
    normal(c[3].vert, c[4].vert, c0vert),
    normal(c[4].vert, c0vert, c[3].vert),

    normal(c0vert, c[4].vert, c[1].vert),
    normal(c[4].vert, c[1].vert, c0vert),
    normal(c[1].vert, c0vert, c[4].vert),
  }
  local cols = {
    c0color, c[1].color, c[2].color,
    c0color, c[2].color, c[3].color,
    c0color, c[3].color, c[4].color,
    c0color, c[4].color, c[1].color,
  }
  local offset = (((pos2.x%size) * size) + pos2.y%size) * 12 + 1

  verts:set(vts, offset, 12)
  normals:set(nms, offset, 12)
  colors:set(cols, offset, 12)
end

local function update_chunks(self)
  local far = self.far
  local size = far * 2 + 1
  local buffers = am.struct_array(size^2 * 12, {
    "vert", "vec3", "normal", "vec3", "color", "vec4"
  })
  local vert = buffers.vert
  local normal = buffers.normal
  local color = buffers.color
  local t0 = os.clock()
  local eye2 = int3(self.camera.eye)
  local queue = self._chunk_queue
  local pull = table.remove

  while true do
    local pos = pull(queue,1)
    local eye = eye2
    while pos do
      self:update_chunk(pos, vert, normal, color)
      if (os.clock()-t0 > am.delta_time/2) then
        coroutine.yield()
        t0 = os.clock()
      end
      pos = pull(queue,1)
    end
    self.bind.vert:set(vert)
    self.bind.normal:set(normal)
    self.bind.color:set(color)

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

local function shader()
  local vert = [[
    precision highp float;
    uniform mat4 MV;
    uniform mat4 P;
    attribute vec3 vert;
    attribute vec3 normal;
    attribute vec4 color;
    varying vec4 v_color;
    varying vec3 v_pos;
    varying vec3 v_normal;
    void main() {
      v_pos = vert;
      v_color = color;
      v_normal = normal;
      gl_Position = P * MV * vec4(vert, 1);
    }
  ]]
  local frag = [[
    precision mediump float;
    uniform mat4 MV;
    uniform vec3 camera;
    uniform vec3 light;
    uniform vec4 sky_color;
    uniform float far;
    varying vec4 v_color;
    varying vec3 v_pos;
    varying vec3 v_normal;
    void main() {
      float dist = distance(v_pos, camera);
      float dist_a = pow(clamp(dist/far, 0.0, 1.0), 2.0);
      vec3 l = normalize((MV * vec4(light, 0.0)).xyz);
      vec3 nm = normalize((MV * vec4(v_normal, 0.0)).xyz);
      // Diffuse light, v_color.a is used to mix ambient vs direct light
      vec4 c = mix(vec4(0), v_color, v_color.a + (1.0-v_color.a) * dot(nm,l));

      if (v_pos.y <= 0.0) {
        c = mix(mix(c, vec4(0,0,0,1),
                               -v_pos.y/3.),
                           vec4(.1,.3,.5,1), 0.6);
      }
      gl_FragColor = vec4(c.rgb, 1.0-dist_a);
    }
  ]]
  return am.program(vert,frag)
end

function map:regenerate()
  local eye = int3(self.camera.eye)
  local far = self.far
  self._chunk_queue = {}
  self:enqueue_chunks(vec2(eye.x-far,eye.z-far), vec2(eye.x+far,eye.z+far))
end

function map:new(camera, far)
  local self = setmetatable({}, self)
  local size = far * 2 + 1
  local binds = am.struct_array(size^2 * 12, {
    "vert", "vec3", "normal", "vec3", "color", "vec4"
  })
  binds.camera = camera.eye
  binds.far = far
  self.bind = am.bind(binds)
  self.camera = camera
  self.far = far
  self.update_chunks = coroutine.wrap(update_chunks)
  self._chunk_queue = {}

  self.node = am.group{
    self.bind
    ^am.cull_face'back'
    ^am.use_program(shader())
    ^am.draw'triangles'
  }
  return self
end

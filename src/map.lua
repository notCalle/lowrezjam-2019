local map = ...
table.merge(map, {
  __index = map
})

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
    rock > 6 and vec3(1.0)
    or rock >= soil-0.5 and vec3(0.5, 0.5, 0.5)
    or soil < 0.1 and vec3(0.7, 0.7, 0.5)
    or vec3(0.1, 0.5, 0.2)

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

local function tile(pos2)
    local c = {}
    c[1] = map:get(pos2)
    c[2] = map:get(pos2 + vec2(0, 1))
    c[3] = map:get(pos2 + vec2(1, 1))
    c[4] = map:get(pos2 + vec2(1, 0))
    c[5] = c[1]
    local c0vert = (c[1].vert + c[2].vert + c[3].vert + c[4].vert) / 4
    local c0color = (c[1].color + c[2].color + c[3].color + c[4].color) / 4

    local vts = {}
    local nms = {}
    local cols = {}
    for v = 1, 4 do
        table.append(vts, { c0vert, c[v].vert, c[v+1].vert })
        table.append(nms, { normal(c0vert, c[v].vert, c[v+1].vert),
                            normal(c[v].vert, c[v+1].vert, c0vert),
                            normal(c[v+1].vert, c0vert, c[v].vert) })
        table.append(cols, { c0color, c[v].color, c[v+1].color })
    end

    return vts, nms, cols
end

local function update_chunks(self)
  local far = self.far
  local size = far * 2 + 1
  local buffers = am.struct_array(size^2 * 12, {
    "vert", "vec3", "normal", "vec3", "color", "vec3"
  })
  local vert = buffers.vert
  local normal = buffers.normal
  local color = buffers.color
  local t0 = os.clock()

  while true do
    local eye = self.camera.eye
    for x = 0, size-1 do
      for y = 0, size-1 do
        local vts, nms, cols = tile(vec2(x+eye.x-far, y+eye.z-far))
        local offset = ((x * size) + y) * 12 + 1
        vert:set(vts, offset, 12)
        normal:set(nms, offset, 12)
        color:set(cols, offset, 12)
      end
      if (os.clock()-t0 > am.delta_time/2) then
        coroutine.yield()
        t0 = os.clock()
      end
    end
    self.bind.vert:set(vert)
    self.bind.normal:set(normal)
    self.bind.color:set(color)
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
    uniform vec3 camera;
    uniform vec3 light;
    uniform vec4 sky_color;
    uniform float far;
    attribute vec3 vert;
    attribute vec3 normal;
    attribute vec3 color;
    varying vec4 v_color;
    varying float v_y;
    varying vec2 v_uv;
    void main() {
      float dist = distance(vert, camera);
      float dist_a = pow(clamp(dist/far, 0.0, 1.0), 2.0);
      vec3 l = normalize((MV * vec4(light, 0.0)).xyz);
      vec3 nm = normalize((MV * vec4(normal, 0.0)).xyz);
      vec3 c = mix(vec3(0.0), color, 0.25 + 0.75 * dot(nm,l));

      v_uv = fract(vert.xz);
      v_y = vert.y;
      v_color = vec4(c, 1.0-dist_a);
      gl_Position = P * MV * vec4(vert, 1);
    }
  ]]
  local frag = [[
    precision mediump float;
    varying vec4 v_color;
    varying float v_y;
    void main() {
      if (v_y < 0.0) {
        gl_FragColor = mix(vec4(0.2,0.3,0.7,v_color.a),v_color,0.2);
      } else {
        gl_FragColor = v_color;
      }
    }
  ]]
  return am.program(vert,frag)
end

function map:new(camera, far)
  local self = setmetatable({}, self)
  local size = far * 2 + 1
  local binds = am.struct_array(size^2 * 12, {
    "vert", "vec3", "normal", "vec3", "color", "vec3"
  })
  binds.camera = camera.eye
  binds.far = far
  self.bind = am.bind(binds)
  self.camera = camera
  self.far = far
  self.update_chunks = coroutine.wrap(update_chunks)

  self:update()

  self.node = self.bind
        ^am.cull_face'back'
        ^am.use_program(shader())
        ^am.draw'triangles'
        :action(function() self:update() end)
  return self
end

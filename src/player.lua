local player = ...
table.merge(player, {
  __index = player,
  height = 0.1,
  speed = vec4(0, 0, 0, 0),
  turnrate = math.rad(90),
})

function player:new(world, origin, heading)
  local self = setmetatable({}, self)
  local origin = origin or vec3(0)
  local heading = heading or 0

  self.world = world
  self.pos = vec3(origin.x or 0,origin.y or 0,origin.z or 0)
  self.heading = heading
  self.pitch = 0.0
  self.torch = 0.0

  return self
end

function player:save(key)
  key = key or 'player'
  am.save_state(key, {
    origin = {
      x = self.pos.x,
      y = self.pos.y,
      z = self.pos.z
    },
    heading = self.heading
  },'json')
end

function player:load(key)
  key = key or 'player'
  local state = am.load_state(key,'json') or {}
  return function(world, origin, heading)
    return self:new(world, origin or state.origin, heading or state.heading)
  end
end

function player:update()
  local dt = am.delta_time
  local win = self.world.window
  local move = vec4(0,-9*dt,0,0)
  local mouse_d = win:mouse_norm_delta()
  local turn, pitch = -mouse_d.x, mouse_d.y
  local speed = self.speed
  local max_s = math.mix(0.5, 1.0, math.clamp(self.pos.y+1.0, 0.0, 1.0))

  if win:key_down'lshift' then max_s = max_s*3 end

  if win:key_down'w' then move = move{z = -2*dt} end
  if win:key_down'a' then move = move{x =   -dt} end
  if win:key_down's' then move = move{z =    dt} end
  if win:key_down'd' then move = move{x =    dt} end

  if win:key_pressed'space' then move = move{y = 2} end

  if win:key_pressed't' then self.torch = 1.0 - self.torch end

  if move.x == 0 then move = move{x = -math.sign(speed.x)*dt} end
  if move.z == 0 then move = move{z = -math.sign(speed.z)*dt} end

  speed = math.clamp(speed + move,
                     vec4(-max_s/2,-100,-max_s,0),
                     vec4(max_s/2,5*max_s,max_s/2,0))
  self.heading = self.heading + self.turnrate * turn

  local dpos = speed * math.rotate4(-self.heading, vec3(0,1,0))
  local pos = self.pos + dpos.xyz * am.delta_time
  local g_y = math.max(-self.height,self.world.map:interpolate(pos.xz).y)
  if pos.y < g_y then speed = speed{y = 0} end

  self.pos = pos{y = math.max(pos.y, g_y)}
  self.speed = speed
  self.pitch = math.clamp(self.pitch + self.turnrate * pitch, -1, 1)
end

--- Return eye pos, dir for camera
function player:eye()
  local pos = self.pos
  local mat = math.rotate4(self.heading, vec3(0,1,0))
            * math.rotate4(self.pitch, vec3(1,0,0))
  local dir = (mat * vec4(0,0,-1,0)).xyz
  return pos + vec3(0,self.height,0), dir
end

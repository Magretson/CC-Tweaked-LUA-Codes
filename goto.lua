-- goto.lua (turtle)
-- Provides goto.run(goal) -> ok, err, final

local heading = dofile("heading.lua")

local function gpsPos()
  local x, y, z = gps.locate(3)
  if not x then return nil, "GPS locate failed" end
  return { x = math.floor(x + 0.5), y = math.floor(y + 0.5), z = math.floor(z + 0.5) }, nil
end

local rightOf = { N="E", E="S", S="W", W="N" }

local function turnTo(target)
  local f = heading.get()
  if f == target then return true end
  for _ = 1, 3 do
    heading.turnRight()
    f = rightOf[f]
    if f == target then return true end
  end
  return false
end

local function forward(n)
  for _ = 1, n do
    if not turtle.forward() then return false, "Blocked while moving forward" end
  end
  return true
end

local function up(n)
  for _ = 1, n do
    if not turtle.up() then return false, "Blocked while moving up" end
  end
  return true
end

local function down(n)
  for _ = 1, n do
    if not turtle.down() then return false, "Blocked while moving down" end
  end
  return true
end

local M = {}

function M.run(goal)
  -- recalibrate heading (simple + robust for now)
  shell.run("orient")

  local start, err = gpsPos()
  if not start then return false, err end

  local dx = goal.x - start.x
  local dy = goal.y - start.y
  local dz = goal.z - start.z

  if dx > 0 then if not turnTo("E") then return false, "turnTo E failed" end
    local ok,e = forward(dx); if not ok then return false,e end
  elseif dx < 0 then if not turnTo("W") then return false, "turnTo W failed" end
    local ok,e = forward(-dx); if not ok then return false,e end
  end

  if dy > 0 then local ok,e = up(dy); if not ok then return false,e end
  elseif dy < 0 then local ok,e = down(-dy); if not ok then return false,e end
  end

  if dz > 0 then if not turnTo("S") then return false, "turnTo S failed" end
    local ok,e = forward(dz); if not ok then return false,e end
  elseif dz < 0 then if not turnTo("N") then return false, "turnTo N failed" end
    local ok,e = forward(-dz); if not ok then return false,e end
  end

  local final, err2 = gpsPos()
  if not final then return false, err2 end

  local reached = (final.x == goal.x) and (final.y == goal.y) and (final.z == goal.z)
  if not reached then
    return false, "Final position mismatch", final
  end
  return true, nil, final
end

return M

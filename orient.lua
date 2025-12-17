-- orient.lua
-- Determines current facing (N/E/S/W) using GPS by moving forward 1 block.

local function getPos()
  local x, y, z = gps.locate(3) -- 3s timeout
  if not x then return nil, "GPS locate failed" end
  return { x = x, y = y, z = z }, nil
end

local function signToDir(dx, dz)
  if dx ==  1 and dz ==  0 then return "E" end
  if dx == -1 and dz ==  0 then return "W" end
  if dx ==  0 and dz ==  1 then return "S" end
  if dx ==  0 and dz == -1 then return "N" end
  return nil
end

-- 1) Record origin
local posO, err = getPos()
if not posO then
  print(err)
  return
end

-- 2) Try move forward
if not turtle.forward() then
  print("Blocked: cannot move forward to determine facing.")
  return
end

-- 3) Record new position
local posN, err2 = getPos()
if not posN then
  -- attempt to return even if GPS failed
  turtle.back()
  print(err2)
  return
end

-- 4) Return to origin position (best-effort)
turtle.back()

-- 5) Compute delta (round because GPS can be float-ish)
local dx = math.floor((posN.x - posO.x) + 0.5)
local dz = math.floor((posN.z - posO.z) + 0.5)

local facing = signToDir(dx, dz)
if not facing then
  print("Unexpected movement delta: dx=" .. tostring(dx) .. " dz=" .. tostring(dz))
  return
end

print("Facing: " .. facing)

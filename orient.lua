-- orient.lua
-- Determines current facing (N/E/S/W) using GPS by moving forward 1 block.

-- LOCAL FUNCTIONS START --
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

-- Ensure there is a clear forward direction, possibly by rotating or changing Y
-- Returns true if a forward move is possible, false otherwise
local function ensureForwardClear()
  -- Try current level first
  for i = 1, 4 do
    if not turtle.detect() then
      return true
    end
    turtle.turnRight()
  end

  -- Try moving up
  local upCount = 0
  if turtle.up() then
    upCount = 1

    for i = 1, 4 do
      if not turtle.detect() then
        -- return to original Y
        turtle.down()
        return true
      end
      turtle.turnRight()
    end

    -- No luck above, go back down
    turtle.down()
    upCount = 0
  end

  -- Try moving down
  if turtle.down() then
    upCount = -1

    for i = 1, 4 do
      if not turtle.detect() then
        -- return to original Y
        turtle.up()
        return true
      end
      turtle.turnRight()
    end

    -- Return to original Y
    turtle.up()
  end

  -- Fully enclosed
  return false
end
-- LOCAL FUNCTIONS START --

-- MAIN LOGIC START--
-- 0) Precheck
if not ensureForwardClear() then
  error("Cannot orient: no free adjacent block in any direction")
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
-- MAIN LOGIC END--

--PRINT MESSAGE--
print("Facing: " .. facing)

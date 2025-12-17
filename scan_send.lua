-- scan_send.lua (turtle)
-- Scans adjacent blocks at current GPS position and sends updates to Map Computer.
-- Skips the direction it came from (known air).

local MAP_ID = 7  

-- ---------- Rednet init ----------
local modem = peripheral.find("modem")
if not modem then error("No modem attached") end
rednet.open(peripheral.getName(modem))

-- ---------- Helpers ----------
local function gpsPos()
  local x, y, z = gps.locate(3)
  if not x then error("GPS locate failed") end
  return { x = math.floor(x + 0.5), y = math.floor(y + 0.5), z = math.floor(z + 0.5) }
end

local function readText(path)
  if not fs.exists(path) then return nil end
  local f = fs.open(path, "r")
  local s = f.readAll()
  f.close()
  return s
end

local function writeText(path, s)
  local f = fs.open(path, "w")
  f.write(s)
  f.close()
end

local function loadFacing()
  local s = readText("facing.txt")
  if not s then error("Missing facing.txt (expected N/E/S/W)") end
  s = s:match("^%s*(%S+)%s*$")
  if s ~= "N" and s ~= "E" and s ~= "S" and s ~= "W" then
    error("Invalid facing in facing.txt: " .. tostring(s))
  end
  return s
end

local dirVec = {
  N = { dx = 0, dz = -1 },
  E = { dx = 1, dz = 0 },
  S = { dx = 0, dz = 1 },
  W = { dx = -1, dz = 0 },
}

local rightOf = { N = "E", E = "S", S = "W", W = "N" }
local leftOf  = { N = "W", W = "S", S = "E", E = "N" }
local opposite= { N = "S", S = "N", E = "W", W = "E" }

-- Turn turtle to face targetDir, updating localFacing
local function turnTo(localFacing, targetDir)
  if localFacing == targetDir then return localFacing end
  -- Try right turns up to 3
  local f = localFacing
  for _ = 1, 3 do
    turtle.turnRight()
    f = rightOf[f]
    if f == targetDir then return f end
  end
  -- Should never get here if dirs are valid
  return f
end

local function parsePos(s)
  -- "x,y,z"
  local x, y, z = s:match("^%s*(-?%d+)%s*,%s*(-?%d+)%s*,%s*(-?%d+)%s*$")
  if not x then return nil end
  return { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
end

local function posToString(p)
  return string.format("%d,%d,%d", p.x, p.y, p.z)
end

-- Determine the absolute direction from prev -> cur (N/E/S/W), or nil
local function movementDir(prev, cur)
  if not prev then return nil end
  local dx = cur.x - prev.x
  local dz = cur.z - prev.z
  if dx == 1 and dz == 0 then return "E" end
  if dx == -1 and dz == 0 then return "W" end
  if dx == 0 and dz == 1 then return "S" end
  if dx == 0 and dz == -1 then return "N" end
  return nil
end

-- ---------- Main ----------
local cur = gpsPos()
local facing = loadFacing()

local prev = parsePos(readText("last_pos.txt") or "")
local moved = movementDir(prev, cur)
local knownAirDir = moved and opposite[moved] or nil -- the neighbor we came FROM is known air

-- Build updates list
local updates = {}

-- Up
do
  local solid = turtle.detectUp()
  table.insert(updates, {
    type = solid and "solid" or "air",
    x = cur.x, y = cur.y + 1, z = cur.z
  })
end

-- Down
do
  local solid = turtle.detectDown()
  table.insert(updates, {
    type = solid and "solid" or "air",
    x = cur.x, y = cur.y - 1, z = cur.z
  })
end

-- Horizontals (N/E/S/W), skipping knownAirDir if available
for _, d in ipairs({ "N", "E", "S", "W" }) do
  if d ~= knownAirDir then
    facing = turnTo(facing, d)
    local solid = turtle.detect()
    table.insert(updates, {
      type = solid and "solid" or "air",
      x = cur.x + dirVec[d].dx,
      y = cur.y,
      z = cur.z + dirVec[d].dz
    })
  else
    -- We already know this neighbor is air (we just came from there)
    table.insert(updates, {
      type = "air",
      x = cur.x + dirVec[d].dx,
      y = cur.y,
      z = cur.z + dirVec[d].dz
    })
  end
end

-- Send batch to map computer
local msg = { op = "update", blocks = updates }
local ok = rednet.send(MAP_ID, msg)
if not ok then
  print("Warning: rednet.send failed (no ack).")
else
  print("Sent " .. tostring(#updates) .. " block updates to map.")
end

-- Save current position as last_pos for next time
writeText("last_pos.txt", posToString(cur))

-- Save facing back (it should be unchanged logically, but we persist anyway)
writeText("facing.txt", facing)

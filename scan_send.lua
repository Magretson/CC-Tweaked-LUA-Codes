-- scan_send.lua (turtle)
-- Scan 6 adjacent blocks at current GPS position and send to Map Computer.

local MAP_ID = 7  -- <- set to your Map Computer ID

local heading = require("heading")

local modem = peripheral.find("modem")
if not modem then error("No modem attached") end
rednet.open(peripheral.getName(modem))

local function gpsPos()
  local x, y, z = gps.locate(3)
  if not x then error("GPS locate failed") end
  return { x = math.floor(x + 0.5), y = math.floor(y + 0.5), z = math.floor(z + 0.5) }
end

local dirVec = {
  N = { dx = 0, dz = -1 },
  E = { dx = 1, dz = 0 },
  S = { dx = 0, dz = 1 },
  W = { dx = -1, dz = 0 },
}

local rightOf = { N="E", E="S", S="W", W="N" }

local function turnTo(target)
  local f = heading.get()
  if f == target then return end
  -- rotate right until we match (max 3)
  for _ = 1, 3 do
    heading.turnRight()
    f = rightOf[f]
    if f == target then return end
  end
end

local cur = gpsPos()
local updates = {}

-- Up / Down
do
  local solid = turtle.detectUp()
  table.insert(updates, { x = cur.x, y = cur.y + 1, z = cur.z, type = solid and "solid" or "air" })
end

do
  local solid = turtle.detectDown()
  table.insert(updates, { x = cur.x, y = cur.y - 1, z = cur.z, type = solid and "solid" or "air" })
end

-- N/E/S/W
for _, d in ipairs({ "N", "E", "S", "W" }) do
  turnTo(d)
  local solid = turtle.detect()
  table.insert(updates, {
    x = cur.x + dirVec[d].dx,
    y = cur.y,
    z = cur.z + dirVec[d].dz,
    type = solid and "solid" or "air"
  })
end

-- Send batch
local msg = { op = "update", blocks = updates }
rednet.send(MAP_ID, msg)
print("Sent " .. #updates .. " updates to map.")

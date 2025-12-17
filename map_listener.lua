-- map_listener.lua

local modem = peripheral.find("modem")
if not modem then error("No modem attached") end
rednet.open(peripheral.getName(modem))

local MAP_FILE = "world_map.db"
local map = {}

-- Load map from disk if it exists
if fs.exists(MAP_FILE) then
  local f = fs.open(MAP_FILE, "r")
  map = textutils.unserialize(f.readAll()) or {}
  f.close()
end

print("Map listener online. Entries:", table.getn(map))

local function saveMap()
  local f = fs.open(MAP_FILE, "w")
  f.write(textutils.serialize(map))
  f.close()
end

while true do
  local senderId, msg = rednet.receive()
  if type(msg) == "table" then
    -- expected format:
    -- { x=..., y=..., z=..., type="air"|"solid"|"unknown" }

    if msg.x and msg.y and msg.z and msg.type then
      local key = msg.x .. "," .. msg.y .. "," .. msg.z
      map[key] = msg.type
      saveMap()
      print("Stored:", key, msg.type)
    end
  end
end

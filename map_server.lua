-- map_server.lua
-- Listens for block updates and stores them uniquely by XYZ (no duplicates).

local MAP_FILE = "world_map.db"

-- --- Rednet init ---
local modem = peripheral.find("modem")
if not modem then error("No modem attached") end
rednet.open(peripheral.getName(modem))

-- --- Load existing map ---
local map = {}
if fs.exists(MAP_FILE) then
  local f = fs.open(MAP_FILE, "r")
  map = textutils.unserialize(f.readAll()) or {}
  f.close()
end

local function keyOf(x, y, z)
  return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

local function save()
  local f = fs.open(MAP_FILE, "w")
  f.write(textutils.serialize(map))
  f.close()
end

print("Map server online. Entries: " .. tostring(#(map))) -- note: # won't count keyed tables reliably

while true do
  local senderId, msg = rednet.receive()

  -- Expect: { op="update", blocks={...} }
  if type(msg) == "table" and msg.op == "update" and type(msg.blocks) == "table" then
    local updated = 0

    for _, b in ipairs(msg.blocks) do
      if type(b) == "table" and b.x and b.y and b.z and b.type then
        local k = keyOf(b.x, b.y, b.z)

        -- Overwrite existing value (prevents duplicates)
        map[k] = b.type
        updated = updated + 1
      end
    end

    save()
    print("Updated " .. tostring(updated) .. " blocks from " .. tostring(senderId))
    -- optional ack:
    rednet.send(senderId, { op="ack", updated=updated })
  end
end

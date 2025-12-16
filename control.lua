-- control.lua (computer)
local side = peripheral.find("modem") and peripheral.getName(peripheral.find("modem")) or nil
if not side then error("No modem found") end
rednet.open(side)

local turtleId = 5 -- <-- replace with your turtle's ID from `id`

rednet.send(turtleId, "dance")
print("Sent 'dance' to turtle " .. turtleId)

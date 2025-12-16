-- control.lua (computer)

local modem = peripheral.find("modem")
if not modem then error("No modem attached") end
local side = peripheral.getName(modem)
rednet.open(side)

local turtleId = 5 -- <-- replace with your turtle ID

print("Commands:")
print("  update <name>  (downloads name.lua onto turtle)")
print("  run <name>     (runs program on turtle)")
print("  dance")
print("  stop")
print("Type 'exit' to quit.")

while true do
  write("> ")
  local line = read()
  if line == "exit" then break end

  rednet.send(turtleId, line)

  local senderId, reply = rednet.receive(2)
  if reply then
    print("Turtle: " .. tostring(reply))
  else
    print("No reply (timeout). Check turtleId/modem range.")
  end
end


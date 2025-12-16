-- listener.lua (turtle)
local side = peripheral.find("modem") and peripheral.getName(peripheral.find("modem")) or nil
if not side then error("No modem found") end

rednet.open(side)
print("Listening. My ID is: " .. os.getComputerID())

while true do
  local senderId, msg = rednet.receive()
  msg = tostring(msg)

  if msg == "dance" then
    print("Command: dance")
    shell.run("dance")  -- runs dance.lua as 'dance'

  elseif msg == "stop" then
    print("Command: stop (not implemented yet)")
    -- We'll add a real stop mechanism in the next step.

  elseif msg == "ping" then
    rednet.send(senderId, "pong")
  end
end

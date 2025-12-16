-- listener.lua (turtle)

local modem = peripheral.find("modem")
if not modem then error("No modem attached") end
local side = peripheral.getName(modem)
rednet.open(side)

local BASE_URL = "https://raw.githubusercontent.com/Magretson/CC-Tweaked-LUA-Codes/main/"

print("Listener online. ID: " .. os.getComputerID())

while true do
  local senderId, msg = rednet.receive()
  msg = tostring(msg)

  -- Commands:
  -- "update <name>"  -> wget BASE_URL..name..".lua" name..".lua"
  -- "run <name>"     -> shell.run(name)
  -- "dance"          -> shell.run("dance")
  -- "stop"           -> os.reboot()

  local cmd, arg = msg:match("^(%S+)%s*(.*)$")
  arg = (arg and arg ~= "") and arg or nil

  if cmd == "update" and arg then
    local url = BASE_URL .. arg .. ".lua"
    local file = arg .. ".lua"
    print("Updating: " .. file)
    local ok = shell.run("wget", url, file)
    rednet.send(senderId, ok and ("OK updated " .. file) or ("FAIL update " .. file))

  elseif cmd == "run" and arg then
    print("Running: " .. arg)
    rednet.send(senderId, "OK running " .. arg)
    shell.run(arg)

  elseif cmd == "dance" then
    rednet.send(senderId, "OK dancing")
    shell.run("dance")

  elseif cmd == "stop" then
    rednet.send(senderId, "OK stopping (reboot)")
    os.reboot()

  else
    rednet.send(senderId, "Unknown command: " .. msg)
  end
end

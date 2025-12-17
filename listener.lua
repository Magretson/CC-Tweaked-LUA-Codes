-- listener.lua (turtle)

local modem = peripheral.find("modem")
if not modem then error("No modem attached") end
local side = peripheral.getName(modem)
rednet.open(side)

local BASE_URL = "https://raw.githubusercontent.com/Magretson/CC-Tweaked-LUA-Codes/main/"

-- Load goto module (movement primitive)
local gotoMod = nil
if fs.exists("goto.lua") then
  gotoMod = dofile("goto.lua")
end

local function parseGoal(s)
  -- accepts "x,y,z" with optional spaces
  local x, y, z = s:match("^%s*(-?%d+)%s*,%s*(-?%d+)%s*,%s*(-?%d+)%s*$")
  if not x then return nil end
  return { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
end

print("Listener online. ID: " .. os.getComputerID())

while true do
  local senderId, msg = rednet.receive()
  msg = tostring(msg)

  -- Commands:
  -- "update <name>"      -> wget BASE_URL..name..".lua" name..".lua"
  -- "run <name>"         -> shell.run(name)
  -- "dance"              -> shell.run("dance")
  -- "goto x,y,z"         -> run goto.lua to move to goal
  -- "stop"               -> os.reboot()

  local cmd, arg = msg:match("^(%S+)%s*(.*)$")
  arg = (arg and arg ~= "") and arg or nil

  if cmd == "update" and arg then
    local url = BASE_URL .. arg .. ".lua"
    local file = arg .. ".lua"
    print("Updating: " .. file)
    local ok = shell.run("wget", url, file)

    -- If we updated goto.lua, reload it so new logic takes effect immediately
    if ok and arg == "goto" then
      gotoMod = dofile("goto.lua")
    end

    rednet.send(senderId, ok and ("OK updated " .. file) or ("FAIL update " .. file))

  elseif cmd == "run" and arg then
    print("Running: " .. arg)
    rednet.send(senderId, "OK running " .. arg)
    shell.run(arg)

  elseif cmd == "dance" then
    rednet.send(senderId, "OK dancing")
    shell.run("dance")

  elseif cmd == "goto" and arg then
    if not gotoMod then
      rednet.send(senderId, "FAIL goto: goto.lua not installed on turtle")
    else
      local goal = parseGoal(arg)
      if not goal then
        rednet.send(senderId, "FAIL goto: format must be x,y,z (example: goto 2,3,-4)")
      else
        print(("Goto request: %d,%d,%d"):format(goal.x, goal.y, goal.z))
        rednet.send(senderId, "OK goto started")

        local ok, err, final = gotoMod.run(goal)

        if ok then
          local fx, fy, fz = final and final.x or 0, final and final.y or 0, final and final.z or 0
          rednet.send(senderId, ("OK goto reached goal. Final: %d,%d,%d"):format(fx, fy, fz))
        else
          if final then
            rednet.send(senderId, ("FAIL goto: %s. Final: %d,%d,%d"):format(tostring(err), final.x, final.y, final.z))
          else
            rednet.send(senderId, ("FAIL goto: %s"):format(tostring(err)))
          end
        end
      end
    end

  elseif cmd == "stop" then
    rednet.send(senderId, "OK stopping (reboot)")
    os.reboot()

  else
    rednet.send(senderId, "Unknown command: " .. msg)
  end
end

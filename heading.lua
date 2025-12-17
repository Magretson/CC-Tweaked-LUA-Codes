-- heading.lua
-- Persistent facing state: N/E/S/W

local rightOf = { N="E", E="S", S="W", W="N" }
local leftOf  = { N="W", W="S", S="E", E="N" }

local function readFacing()
  if not fs.exists("facing.txt") then return nil end
  local f = fs.open("facing.txt", "r")
  local s = f.readAll()
  f.close()
  s = s and s:match("^%s*(%S+)%s*$")
  if s == "N" or s == "E" or s == "S" or s == "W" then return s end
  return nil
end

local function writeFacing(facing)
  local f = fs.open("facing.txt", "w")
  f.write(facing)
  f.close()
end

local facing = readFacing()

local M = {}

function M.get()
  if not facing then error("Facing unknown: run orient.lua first") end
  return facing
end

function M.set(newFacing)
  if newFacing ~= "N" and newFacing ~= "E" and newFacing ~= "S" and newFacing ~= "W" then
    error("Invalid facing: " .. tostring(newFacing))
  end
  facing = newFacing
  writeFacing(facing)
end

function M.turnRight()
  if not turtle.turnRight() then return false end
  facing = rightOf[M.get()]
  writeFacing(facing)
  return true
end

function M.turnLeft()
  if not turtle.turnLeft() then return false end
  facing = leftOf[M.get()]
  writeFacing(facing)
  return true
end

return M

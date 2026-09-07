package.path = "./?.lua;./?/init.lua;" .. package.path
if not bit then bit = require("bit") end
local noop = function() end
local FONT = { getHeight=function() return 12 end, getWidth=function(_,s) return #(s or "")*6 end, setFilter=noop }
local G = setmetatable({}, { __index=function() return noop end })
G.newFont=function() return FONT end; G.newCanvas=function() return {setFilter=noop} end
G.newShader=function() return {send=noop} end
G.getDimensions=function() return 640,480 end; G.getWidth=function() return 640 end; G.getHeight=function() return 480 end
G.push=noop; G.pop=noop; G.translate=noop; G.scale=noop
local q=false
love = { graphics=G, timer={getTime=function() return 0 end}, event={quit=function() q=true end},
  audio=setmetatable({newSource=function() return setmetatable({},{__index=function() return noop end}) end},{__index=function() return noop end}),
  keyboard={isDown=function() return false end},
  filesystem=setmetatable({getInfo=function() return nil end, read=function() return nil end,
    write=function() return true end, createDirectory=noop}, {__index=function() return noop end}) }
package.loaded.love=love; package.preload["love"]=function() return love end
local fails=0
local function ck(c,m) if not c then fails=fails+1; print("  FAIL: "..m) end end
dofile("./main.lua")
ck(pcall(love.load), "love.load")
local fskit=require("fskit")
local function frame(n) for _=1,(n or 1) do
  local a,e1=pcall(love.update,0.05); ck(a,"update: "..tostring(e1))
  local b,e2=pcall(love.draw);        ck(b,"draw: "..tostring(e2))
end end
local function press(x) OnKeyPress(x); frame(1) end
frame(3)
-- add an alarm: Y opens edit
press("y"); frame(3)
press("down"); press("right"); press("left")     -- fiddle fields
press("y"); frame(3)                               -- preset time picker
press("down"); press("a"); frame(2)               -- pick -> back to edit
press("up"); press("up"); press("a"); frame(2)    -- label picker (field 3, A)
press("down"); press("a"); frame(2)               -- pick a preset label -> edit
press("a"); frame(3)                               -- save (field 1) -> main
-- theme picker via R1
press("r1"); frame(2); press("down"); press("a"); frame(3)
-- edit existing
press("a"); frame(3); press("b"); frame(2)         -- open edit, cancel
-- exit dialog
press("b"); frame(3)
ck(fskit.scene.overlay() ~= nil, "B opens shared exit dialog overlay")
fskit.scene.input("b"); frame(3)
ck(fskit.scene.overlay() == nil and not q, "Stay closes dialog, no quit")
press("b"); frame(2); fskit.scene.input("a"); frame(2)
ck(q, "exit dialog A -> quit")
print(fails==0 and "\nCM SMOKE OK" or ("\n"..fails.." FAILURES"))
os.exit(fails==0 and 0 or 1)

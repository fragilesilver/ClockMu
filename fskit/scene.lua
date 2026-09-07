-- fskit/scene.lua
-- Scene registry + the fade-to-black transition, promoted from BatteryMu's
-- gotoScene / transAlpha / transDir. A scene is a table with any of:
--   enter(payload)  leave()  update(dt)  draw()  input(button)
--
--   fskit.scene.register{ main = {...}, theme = {...}, exit = {...} }
--   fskit.scene.start("main")
--   fskit.scene.go("theme")                 -- fade out -> swap -> fade in
--   fskit.scene.go("main", payload, true)   -- instant
-- Wire from love callbacks: fskit.scene.update(dt) / .draw() / .input(name)

local motion = require("fskit.motion")

local TRANS_SPEED = 4.0            -- BatteryMu value (~250ms each way)

local scene = {}
local scenes = {}
local cur, curName = nil, nil
local overlay = nil               -- modal drawn over the frozen scene

local a, dir, target, targetPayload = 0, 0, nil, nil   -- transition state

function scene.register(tbl)
    for name, s in pairs(tbl) do scenes[name] = s end
end

function scene.now() return curName end
function scene.get(name) return scenes[name] end

local function activate(name, payload)
    if cur and cur.leave then cur.leave() end
    cur, curName = scenes[name], name
    if cur and cur.enter then cur.enter(payload) end
end

function scene.start(name, payload)
    activate(name, payload)
    a, dir = 0, 0
end

function scene.go(name, payload, instant)
    if name == curName and not overlay then return end
    if instant or not motion.enabled then
        activate(name, payload); a, dir = 0, 0; return
    end
    target, targetPayload, dir = name, payload, 1     -- fade to black
end

function scene.busy() return dir ~= 0 end

-- ---- modal overlay (fskit.ui.dialog uses this) --------------------
function scene.setOverlay(o) overlay = o end
function scene.clearOverlay() overlay = nil end
function scene.overlay() return overlay end

-- ---- love wiring -------------------------------------------------
function scene.update(dt)
    motion.update(dt)
    if overlay and overlay.update then overlay.update(dt) end
    if cur and cur.update then cur.update(dt) end

    if dir == 1 then
        a = math.min(1, a + dt * TRANS_SPEED)
        if a >= 1 then activate(target, targetPayload); target = nil; dir = -1 end
    elseif dir == -1 then
        a = math.max(0, a - dt * TRANS_SPEED)
        if a <= 0 then dir = 0 end
    end
end

function scene.draw()
    if cur and cur.draw then cur.draw() end
    if overlay and overlay.draw then overlay.draw() end
    if a > 0.001 then
        love.graphics.setColor(0, 0, 0, a)
        love.graphics.rectangle("fill", 0, 0,
            require("fskit.screen").W, require("fskit.screen").H)
    end
end

function scene.input(button)
    if dir ~= 0 then return end                 -- swallow input mid-fade
    if overlay then
        if overlay.input then overlay.input(button) end
        return
    end
    if cur and cur.input then cur.input(button) end
end

return scene

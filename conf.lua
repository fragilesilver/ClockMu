-- ClockMu -- LÖVE configuration
-- muOS Andromeda 2606.0. Runs at the panel's NATIVE size: mux_launch.sh passes
-- "WxH" (from the device's mux/width and mux/height) as an argument, and fskit
-- picks its screen profile from the window (640x480 RG35XX family, 720x480
-- RG34XX, 720x720 RGCubeXX; anything else is letterboxed). Without an argument:
-- 640x480, exactly as before.

local W, H = 640, 480
for _, a in pairs(arg or {}) do
    local w, h = tostring(a):match("^(%d+)x(%d+)$")
    if w then W, H = tonumber(w), tonumber(h) end
end
-- CLOCKMU_WINDOWED=WxH: a small, minimised window for desktop tests and
-- screenshots (never set on the device)
local dw, dh = (os.getenv("CLOCKMU_WINDOWED") or ""):match("^(%d+)x(%d+)$")

function love.conf(t)
    t.identity            = "ClockMu"      -- save dir: <data home>/ClockMu/
    t.version             = "11.5"
    t.console             = false
    t.appendidentity      = true

    t.window.title        = "ClockMu"
    t.window.width        = dw and tonumber(dw) or W
    t.window.height       = dh and tonumber(dh) or H
    t.window.fullscreen   = dw == nil
    t.window.fullscreentype = "exclusive"
    t.window.minimized    = dw ~= nil
    t.window.resizable    = false
    t.window.borderless   = true
    t.window.vsync        = dw and 0 or 1
    t.window.highdpi      = false
    t.window.displayindex = 1

    -- Trim modules ClockMu never uses (lighter on the H700).
    t.modules.physics = false
    t.modules.video   = false
    t.modules.touch   = false
    t.modules.mouse   = false
end

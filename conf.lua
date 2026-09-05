-- ClockMu -- LÖVE configuration
-- muOS Andromeda 2606.0, whole RG35XX family (Allwinner H700, 640x480).
-- The real render target is decided in love.load from what muOS hands us
-- (launch arg "WxH", else the framebuffer size); fskit.screen letterboxes a
-- fixed 640x480 virtual canvas onto it, so nothing here is device-specific.

function love.conf(t)
    t.identity            = "ClockMu"      -- save dir: <data home>/ClockMu/
    t.version             = "11.5"
    t.console             = false
    t.appendidentity      = true

    t.window.title        = "ClockMu"
    t.window.width        = 640
    t.window.height       = 480
    t.window.fullscreen   = true
    t.window.fullscreentype = "exclusive"
    t.window.resizable    = false
    t.window.borderless   = true
    t.window.vsync        = 1
    t.window.highdpi      = false
    t.window.displayindex = 1

    -- Trim modules ClockMu never uses (lighter on the H700).
    t.modules.physics = false
    t.modules.video   = false
    t.modules.touch   = false
    t.modules.mouse   = false
end

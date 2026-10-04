-- fskit  --  shared LÖVE kit for the MustardOS apps
--           (ClockMu / JarMu / BatteryMu / SwapMu)
-- Canonical source: apps/fskit/  ->  repo fragilesilver/fskit
-- Vendored into each app at <app>/fskit/ via vendor.sh (pinned VERSION).
--
--   local fskit = require("fskit")
--   function love.load()
--       fskit.load()                         -- fonts, glyphs, virtual canvas
--       fskit.theme.bind{ load = ..., save = ... }
--       fskit.scene.register{ ... }; fskit.scene.start("main")
--   end
--   function love.update(dt) fskit.scene.update(dt) end
--   function love.draw()
--       fskit.screen.begin()
--       fskit.scene.draw()                   -- or draw at 640x480 directly
--       fskit.screen.finish(shader)          -- shader optional (JarMu CRT)
--   end
--   function love.resize(w, h) fskit.screen.resize(w, h) end

local fskit = {
    _VERSION = "0.3.0",
    theme    = require("fskit.theme"),
    themes   = require("fskit.themes"),
    screen   = require("fskit.screen"),
    layout   = require("fskit.layout"),
    font     = require("fskit.font"),
    glyph    = require("fskit.glyph"),
    input    = require("fskit.input"),
    motion   = require("fskit.motion"),
    scene    = require("fskit.scene"),
    crt      = require("fskit.crt"),
    muos     = require("fskit.muos"),
    ui = {
        header = require("fskit.ui.header"),
        footer = require("fskit.ui.footer"),
        list   = require("fskit.ui.list"),
        dialog = require("fskit.ui.dialog"),
        marquee = require("fskit.ui.marquee"),
        card   = require("fskit.ui.card"),
        textview = require("fskit.ui.textview"),
        osk    = require("fskit.ui.osk"),
        themepicker = require("fskit.ui.themepicker"),
        util   = require("fskit.ui.util"),
    },
}

-- one-shot resource load; call from love.load()
function fskit.load()
    fskit.font.load()
    fskit.glyph.load()
    fskit.screen.load()
end

-- convenience: hook love input callbacks straight into the scene manager,
-- keeping fskit.input's held-button tracking for hold-to-confirm patterns.
function fskit.hookInput()
    fskit.input.hook(function(name)
        fskit.input.press(name)
        fskit.scene.input(name)
    end)
    local fromKey, fromPad = fskit.input.fromKey, fskit.input.fromPad
    function love.keyreleased(k)
        local n = fromKey(k); if n then fskit.input.release(n) end
    end
    function love.gamepadreleased(_, b)
        local n = fromPad(b); if n then fskit.input.release(n) end
    end
end

return fskit

-- fskit/layout.lua
-- One place for the 640x480 virtual-canvas geometry. Everything routes through
-- these so a future HDMI resolution only changes this file.

local screen = require("fskit.screen")

local layout = {}

layout.SW, layout.SH = screen.W, screen.H
layout.HDR_H    = 44
layout.FOOTER_H = 40                       -- v1 decision: 40 over BatteryMu's 36
layout.PAD      = 16
layout.RADIUS   = 8                        -- shared card/row corner
layout.SHADOW   = { 0, 0, 0, 0.35 }

function layout.headerRect() return 0, 0, layout.SW, layout.HDR_H end
function layout.footerRect() return 0, layout.SH - layout.FOOTER_H, layout.SW, layout.FOOTER_H end

-- x, y, w, h of the area between header and footer
function layout.content()
    local y = layout.HDR_H + 4
    return layout.PAD, y, layout.SW - layout.PAD * 2, layout.SH - layout.FOOTER_H - y - 4
end

return layout

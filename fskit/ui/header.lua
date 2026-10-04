-- fskit/ui/header.lua
-- Top chrome: a solid accent block with the title in display type (UPPERCASE) on
-- the left and an optional small text on the right, kept inside the safe area so
-- a cropped panel still shows it. Text is on_accent.
--
--   header.draw{ title = "Alarms", right = "12:41", centre = "ABC" }
--
-- A title too long for the space left by `right` slides (fskit.ui.marquee).

local theme   = require("fskit.theme")
local font    = require("fskit.font")
local screen  = require("fskit.screen")
local layout  = require("fskit.layout")
local marquee = require("fskit.ui.marquee")

local header = {}

function header.height() return layout.HDR_H end

function header.draw(o)
    o = o or {}
    local h   = o.h or layout.HDR_H
    local pad = o.pad or math.max(layout.PAD, screen.SAFE)
    local W   = screen.W

    theme.rgba("accent")
    love.graphics.rectangle("fill", 0, 0, W, h)

    local right_w = 0
    if o.right then
        local f = o.rightFont or font.sm
        love.graphics.setFont(f)
        right_w = f:getWidth(o.right)
        theme.rgba("on_accent", 0.85)
        love.graphics.print(o.right, W - pad - right_w, (h - f:getHeight()) / 2)
        right_w = right_w + 16
    end

    if o.title then
        local f = o.titleFont or font.xl
        theme.rgba("on_accent")
        marquee(o.title:upper(), pad, (h - f:getHeight()) / 2, W - pad * 2 - right_w,
            { font = f, active = true })
    end

    if o.centre then
        local f = o.centreFont or font.xs
        love.graphics.setFont(f)
        theme.rgba("on_accent", 0.7)
        love.graphics.print(o.centre, (W - f:getWidth(o.centre)) / 2, (h - f:getHeight()) / 2)
    end
end

return header

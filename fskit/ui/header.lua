-- fskit/ui/header.lua
-- Top chrome bar: title left, optional centre + right slots, kept inside the
-- safe area so a cropped panel still shows it.
--
--   header.draw{ title = "ClockMu", centre = "Ocean Blue", right = "07:41" }

local theme  = require("fskit.theme")
local font   = require("fskit.font")
local screen = require("fskit.screen")

local header = {}

header.H = 44

function header.draw(o)
    o = o or {}
    local h   = o.h or header.H
    local pad = o.pad or screen.SAFE

    theme.rgba("bg_header")
    love.graphics.rectangle("fill", 0, 0, screen.W, h)
    theme.rgba("separator", 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, h - 0.5, screen.W, h - 0.5)

    if o.title then
        local f = o.titleFont or font.lg
        love.graphics.setFont(f)
        theme.rgba("accent")
        love.graphics.print(o.title, pad, (h - f:getHeight()) / 2)
    end

    if o.right then
        local f = o.rightFont or font.sm
        love.graphics.setFont(f)
        theme.rgba("text_secondary")
        love.graphics.print(o.right, screen.W - pad - f:getWidth(o.right),
            (h - f:getHeight()) / 2)
    end

    if o.centre then
        local f = o.centreFont or font.xs
        love.graphics.setFont(f)
        theme.rgba("text_disabled")
        love.graphics.print(o.centre, (screen.W - f:getWidth(o.centre)) / 2,
            (h - f:getHeight()) / 2)
    end
end

return header

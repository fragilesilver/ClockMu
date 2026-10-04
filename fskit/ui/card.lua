-- fskit/ui/card.lua
-- Cards and bars, in the Andromeda style: a bg_panel block with a 6 px accent
-- bar down its left edge; a progress bar on a separator track.
--
--   card.draw(x, y, w, h, { role = "accent", color = {r,g,b} })   -- the block only
--   card.stat(x, y, w, h, label, value, {
--       role = / color =,            -- the accent bar (theme role, or an {r,g,b})
--       valueRole = / valueColor =,  -- the value's colour
--       sub = "constant charge limit", subColor = {r,g,b},  -- a small line under the value
--       valueFont =, alpha = 1 })    -- alpha pulses a critical value
--   card.bar(x, y, w, h, frac, { role = "accent" / color = {r,g,b} })

local theme  = require("fskit.theme")
local font   = require("fskit.font")
local layout = require("fskit.layout")
local util   = require("fskit.ui.util")
local marquee = require("fskit.ui.marquee")

local card = {}

function card.draw(x, y, w, h, o)
    o = o or {}
    util.barred(x, y, w, h, layout.BAR, layout.RADIUS, o.role or "accent", "bg_panel", o.color)
end

-- a labelled value: small label above, display-size value below
function card.stat(x, y, w, h, label, value, o)
    o = o or {}
    card.draw(x, y, w, h, o)
    local pad = 14
    local lx, lw = x + layout.BAR + pad, w - layout.BAR - pad * 2
    local lf, vf = o.labelFont or font.xs, o.valueFont or font.xl
    local gap = 2
    local total = lf:getHeight() + gap + vf:getHeight() + (o.sub and (gap + lf:getHeight()) or 0)
    local ty = y + (h - total) / 2
    love.graphics.setFont(lf)
    theme.rgba("text_secondary")
    love.graphics.print(tostring(label):upper(), lx, ty)
    local a = o.alpha or 1
    if o.valueColor then love.graphics.setColor(o.valueColor[1], o.valueColor[2], o.valueColor[3], a)
    else theme.rgba(o.valueRole or "text_primary", a) end
    marquee(tostring(value), lx, ty + lf:getHeight() + gap, lw, { font = vf })
    if o.sub then
        love.graphics.setFont(lf)
        if o.subColor then love.graphics.setColor(o.subColor[1], o.subColor[2], o.subColor[3], 1)
        else theme.rgba("text_disabled") end
        marquee(tostring(o.sub), lx, ty + lf:getHeight() + gap + vf:getHeight() + gap, lw, { font = lf })
    end
end

-- progress bar; `frac` 0..1. segments = a retro-looking cell bar
function card.bar(x, y, w, h, frac, o)
    o = o or {}
    local r = math.min(layout.RADIUS, h / 2)
    theme.rgba("separator")
    love.graphics.rectangle("fill", x, y, w, h, r, r)
    frac = util.clamp(frac or 0, 0, 1)
    if frac > 0 then
        if o.color then love.graphics.setColor(o.color[1], o.color[2], o.color[3], o.color[4] or 1)
        else theme.rgba(o.role or "accent") end
        love.graphics.rectangle("fill", x, y, math.max(h, w * frac), h, r, r)
    end
end

return card

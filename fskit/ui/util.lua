-- fskit/ui/util.lua
-- Small helpers shared by the widgets.

local theme = require("fskit.theme")

local util = {}

local function lin(c) return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4 end
local function lum(r, g, b) return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) end

-- WCAG contrast ratio of two {r,g,b} triples (0..1)
function util.contrast(a, b)
    local la, lb = lum(a[1], a[2], a[3]), lum(b[1], b[2], b[3])
    if la < lb then la, lb = lb, la end
    return (la + 0.05) / (lb + 0.05)
end

-- The role that reads best as text on a fill drawn in `fillRole`: on_accent
-- normally, text_primary when that has more contrast (a warn/danger button).
function util.readable(fillRole)
    local fill = { theme.get(fillRole) }
    local a, b = { theme.get("on_accent") }, { theme.get("text_primary") }
    return util.contrast(a, fill) >= util.contrast(b, fill) and "on_accent" or "text_primary"
end

-- rounded rect with only the right corners rounded is not in LÖVE; this draws a
-- rect with an accent bar down the left (cards): the bar is a rounded rect, the
-- panel a rounded rect laid over it, so only `bar` px of the bar show.
function util.barred(x, y, w, h, bar, radius, barRole, panelRole, barColor)
    if barColor then love.graphics.setColor(barColor[1], barColor[2], barColor[3], barColor[4] or 1)
    else theme.rgba(barRole or "accent") end
    love.graphics.rectangle("fill", x, y, bar + radius, h, radius, radius)
    theme.rgba(panelRole or "bg_panel")
    love.graphics.rectangle("fill", x + bar, y, w - bar, h, radius, radius)
end

function util.clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

return util

-- fskit/ui/footer.lua
-- Declarative button-hint bar. Left items pack from the left safe edge, items with
-- side = "right" pack from the right, measured so nothing clips on a cropped panel.
--
--   footer.draw{
--     { icon = "a", label = "Edit" },
--     { icon = "x", label = "New" },
--     { icon = "b", label = "Back", side = "right" },
--   }
--
-- Each glyph REACTS to its physical button (fskit.input): while the button is
-- held (or for 120 ms after a quick tap) it squishes, brightens and gets a soft
-- ring; on release it springs back with a small overshoot. With reduce-motion
-- on (fskit.motion.enabled = false) it just lights up while held.
--
-- If the hints do not fit the width, the gap and then the font shrink, and as a
-- last resort they go on two rows inside the bar (never clipped).
--
-- Options (2nd arg, all optional): x, w, y, h, pad, font.

local theme   = require("fskit.theme")
local glyph   = require("fskit.glyph")
local font    = require("fskit.font")
local screen  = require("fskit.screen")
local layout  = require("fskit.layout")
local motion  = require("fskit.motion")
local input   = require("fskit.input")

local footer = {}

footer.GAP      = 18   -- between hint groups
footer.ICON_GAP = 7    -- glyph -> label
footer.SQUISH_X, footer.SQUISH_Y = 0.22, 0.12      -- how far a held glyph shrinks

local anim = {}        -- icon name -> { pos, vel, t }

-- glyph spring: 0 at rest .. 1 pressed (overshoots a little on release)
local function glyphState(name)
    local s = anim[name]
    if not s then s = { pos = 0, vel = 0, t = motion.time() }; anim[name] = s end
    local now = motion.time()
    local dt = now - s.t
    s.t = now
    if dt > 0 then motion.spring(s, input.isShown(name) and 1 or 0, dt) end
    return s.pos
end
footer._glyphState = glyphState        -- for tests

local function size(item)
    local g = glyph.get(item.icon)
    if not g then return 0, 0 end
    local sc = glyph.scaleFor(item.icon)
    return g:getWidth() * sc, g:getHeight() * sc
end

local function hintWidth(item, f, gapIcon)
    local iw = size(item)
    return (iw > 0 and iw + gapIcon or 0) + f:getWidth(item.label)
end

local function drawHint(item, x, y, h, f, gapIcon, k)
    local iw, ih = size(item)
    local p = glyphState(item.icon)
    local g = glyph.get(item.icon)
    if g then
        local sc = glyph.scaleFor(item.icon) * k
        local cx, cy = x + iw / 2, y + h / 2
        local sx = 1 - footer.SQUISH_X * p
        local sy = 1 - footer.SQUISH_Y * p
        if p > 0.02 then                                   -- soft ring while pressed
            theme.rgba("accent", 0.30 * math.min(1, p))
            local r = ih * k * (0.62 + 0.30 * p)
            love.graphics.circle("fill", cx, cy, r)
        end
        theme.rgba(p > 0.5 and "accent_glow" or "accent")
        love.graphics.draw(g, cx, cy, 0, sc * sx, sc * sy, g:getWidth() / 2, g:getHeight() / 2)
    end
    love.graphics.setFont(f)
    theme.rgba(p > 0.3 and "text_primary" or "text_secondary")
    love.graphics.print(item.label, x + (iw > 0 and (iw + gapIcon) or 0), y + (h - f:getHeight()) / 2)
end

local function measure(items, f, gap, gapIcon)
    local total = 0
    for i, it in ipairs(items) do total = total + hintWidth(it, f, gapIcon) + (i > 1 and gap or 0) end
    return total
end

function footer.draw(items, opt)
    opt = opt or {}
    local h   = opt.h or layout.FOOTER_H
    local x   = opt.x or 0
    local w   = opt.w or screen.W
    local y   = opt.y or (screen.H - h)
    local pad = opt.pad or math.max(layout.PAD, screen.SAFE)

    theme.rgba("bg_btn_bar")
    love.graphics.rectangle("fill", x, y, w, h)

    local f, gap, gapIcon, k = opt.font or font.sm, footer.GAP, footer.ICON_GAP, 1
    local avail = w - pad * 2
    if measure(items, f, gap, gapIcon) > avail then gap = 10 end
    if measure(items, f, gap, gapIcon) > avail then f = font.xs end
    local rows = { items }
    if measure(items, f, gap, gapIcon) > avail and #items > 1 then
        -- two compact rows: the first half, then the rest
        local half = math.ceil(#items / 2)
        local a, b = {}, {}
        for i, it in ipairs(items) do (i <= half and a or b)[#(i <= half and a or b) + 1] = it end
        rows, k = { a, b }, 0.8
    end

    local rh = h / #rows
    for r, row in ipairs(rows) do
        local ry = y + (r - 1) * rh
        local lx = x + pad
        for _, it in ipairs(row) do
            if (it.side or "left") == "left" then
                drawHint(it, lx, ry, rh, f, gapIcon, k)
                lx = lx + hintWidth(it, f, gapIcon) + gap
            end
        end
        local rx = x + w - pad
        for i = #row, 1, -1 do
            local it = row[i]
            if it.side == "right" then
                rx = rx - hintWidth(it, f, gapIcon)
                drawHint(it, rx, ry, rh, f, gapIcon, k)
                rx = rx - gap
            end
        end
    end
end

-- total width the hints need at the default font (tests: "do 6 hints fit?")
function footer.width(items, f)
    return measure(items, f or font.sm, footer.GAP, footer.ICON_GAP)
end

return footer

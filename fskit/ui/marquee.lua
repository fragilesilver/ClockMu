-- fskit/ui/marquee.lua
-- One line of text in a fixed width. When it fits, it is just printed. When
-- it doesn't:
--   * active (the focused row, a title)  -> it waits, slides left until its
--     end is visible, waits, then jumps back and repeats
--   * inactive                           -> it is cut with "..." so it never
--     spills into the next row
-- Drawn into fskit's 640x480 canvas, so the clip is a plain scissor in canvas
-- coordinates. With motion off (reduce-motion) active text is truncated too.
--
--   fskit.ui.marquee(text, x, y, w, { active = focused, align = "left", font = f })
--
-- Uses o.font (else the current font) and the current colour. With no font
-- at all it just prints.

local motion = require("fskit.motion")

local PAUSE = 1.5      -- seconds at each end
local SPEED = 40       -- px per second

local started = {}     -- text -> motion.time() it became active
local last = {}        -- text -> motion.time() it was last drawn active
local seen = 0

local function ellipsize(font, text, w)
    if font:getWidth(text) <= w then return text end
    local dots = "..."
    local lo, hi = 0, #text
    while lo < hi do                       -- longest prefix that fits with "..."
        local mid = math.floor((lo + hi + 1) / 2)
        if font:getWidth(text:sub(1, mid) .. dots) <= w then lo = mid else hi = mid - 1 end
    end
    -- don't cut a UTF-8 sequence in half
    local cut = text:sub(1, lo):gsub("[\192-\255][\128-\191]*$", "")
    return cut .. dots
end

return function(text, x, y, w, o)
    o = o or {}
    text = tostring(text or "")
    local font = o.font or love.graphics.getFont()
    if not font then love.graphics.print(text, x, y); return end
    if o.font then love.graphics.setFont(o.font) end
    local tw = font:getWidth(text)

    if tw <= w then
        local align = o.align or "left"
        local dx = align == "center" and (w - tw) / 2 or (align == "right" and (w - tw) or 0)
        love.graphics.print(text, math.floor(x + dx), y)
        return
    end

    if not o.active or not motion.enabled then
        love.graphics.print(ellipsize(font, text, w), x, y)
        return
    end

    local now = motion.time()
    -- now and then, forget texts not drawn for a while (only ones that are
    -- off screen -- clearing everything would restart long names mid-scroll)
    seen = seen + 1
    if seen > 600 then
        seen = 0
        for k, at in pairs(last) do
            if now - at > 5 then last[k], started[k] = nil, nil end
        end
    end
    -- refocused after a break: start again from the beginning
    if not last[text] or now - last[text] > 0.25 then started[text] = now end
    last[text] = now
    local travel = tw - w
    local cycle = PAUSE + travel / SPEED + PAUSE
    local t = (now - started[text]) % cycle
    local off = 0
    if t > PAUSE then off = math.min(travel, (t - PAUSE) * SPEED) end

    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.intersectScissor(x, y - 2, w, font:getHeight() + 4)
    love.graphics.print(text, math.floor(x - off), y)
    if sx then love.graphics.setScissor(sx, sy, sw, sh) else love.graphics.setScissor() end
end

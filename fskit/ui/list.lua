-- fskit/ui/list.lua
-- Vertical picker list, Andromeda style: the focused row is a SOLID ACCENT BLOCK
-- (text on_accent). The block glides to the new row, the focused row grows 2 %,
-- a long list scrolls smoothly and shows a slim position bar. The caller draws
-- each row's content.
--
--   fskit.ui.list(items, sel, {
--     id = "alarms",                  -- keeps the glide/scroll state; default: the rect
--     x=, y=, w=, h=,                 -- default: fskit.layout.content()
--     rowH = layout.ROW_H, gap = layout.ROW_GAP,
--     empty = "nothing here",
--     draw = function(item, x, y, w, rowH, focused, f) ... end,
--   })
--   -- inside draw: use theme.rgba(focused and "on_accent" or "text_primary").
--   -- f (0..1) is how much of the glide is on this row, for colour blends.
--
-- Navigation is part of the widget (the button contract, docs/andromeda-design.md):
--   sel = fskit.ui.list.nav(sel, key, #items, fskit.ui.list.pageSize{ ... })
--   up/down one row (wrapping) · L1/R1 one page · L2/R2 100 rows (clamped);
--   returns nil for any other key.
--
-- With reduce-motion on (fskit.motion.enabled = false) everything is instant.

local theme  = require("fskit.theme")
local font   = require("fskit.font")
local layout = require("fskit.layout")
local motion = require("fskit.motion")
local util   = require("fskit.ui.util")

local list = {}

list.JUMP  = 100         -- L2 / R2
list.BUMP  = 0.02        -- focused row grows by this fraction
list.GLIDE = 20          -- how fast the highlight chases the selection (1/s)
list.BAR_W = 4           -- position bar width

local states = {}        -- id -> { pos, topT, topf, t }

local function rect(o)
    local cx, cy, cw, ch = layout.content()
    return o.x or cx, o.y or cy, o.w or cw, o.h or ch
end

-- rows per page for a list drawn with these options
function list.pageSize(o)
    o = o or {}
    local _, _, _, h = rect(o)
    local rowH, gap = o.rowH or layout.ROW_H, o.gap or layout.ROW_GAP
    return math.max(1, math.floor((h + gap) / (rowH + gap)))
end

-- the new selection for button k, or nil when k is not a navigation key
function list.nav(sel, k, n, per)
    if n <= 0 then return nil end
    if k == "up" then return sel <= 1 and n or sel - 1 end
    if k == "down" then return sel >= n and 1 or sel + 1 end
    local d = ({ l1 = -(per or 1), r1 = per or 1, l2 = -list.JUMP, r2 = list.JUMP })[k]
    if not d then return nil end
    return util.clamp(sel + d, 1, n)
end

-- forget a list's glide/scroll state (it jumps straight to the selection next draw)
function list.reset(id) if id then states[id] = nil else states = {} end end

return setmetatable(list, { __call = function(_, items, sel, o)
    o = o or {}
    local x, y, w, h = rect(o)
    local rowH, gap = o.rowH or layout.ROW_H, o.gap or layout.ROW_GAP
    local stride = rowH + gap
    local n = #items
    local per = math.max(1, math.floor((h + gap) / stride))
    sel = util.clamp(sel or 1, 1, math.max(1, n))
    -- a list that scrolls keeps its position bar inside its own rect
    local barRoom = (n > per) and (list.BAR_W + 8) or 0
    w = w - barRoom

    local key = o.id or (x .. "," .. y .. "," .. w .. "," .. h)
    local now = motion.time()
    local st = states[key]
    if not st then
        local top = util.clamp(sel - per + 1, 1, math.max(1, n - per + 1))   -- window that holds sel
        if sel <= per then top = 1 end
        st = { pos = sel, topT = top, topf = top - 1, t = now }
        states[key] = st
    end
    local dt = now - st.t
    st.t = now

    -- keep the selection inside the window (the window only moves when it must)
    if sel < st.topT then st.topT = sel elseif sel > st.topT + per - 1 then st.topT = sel - per + 1 end
    st.topT = util.clamp(st.topT, 1, math.max(1, n - per + 1))

    st.pos  = motion.approach(st.pos,  sel,          list.GLIDE,      dt)
    st.topf = motion.approach(st.topf, st.topT - 1,  list.GLIDE * 0.8, dt)

    -- clip to the list, a little wider so the 2 % bump is not cut off
    local sx, sy, sw, sh = love.graphics.getScissor()
    -- whole rows only (a clipped sliver of the next row looks like a glitch)
    love.graphics.intersectScissor(x - 8, y, w + 20 + barRoom, per * stride - gap)

    if n > 0 then
        -- the focus block
        local hy = y + (st.pos - 1 - st.topf) * stride
        local bump = list.BUMP * (motion.enabled and 1 or 0)
        local bw, bh = w * (1 + bump), rowH * (1 + bump)
        theme.rgba("accent")
        love.graphics.rectangle("fill", x - (bw - w) / 2, hy - (bh - rowH) / 2, bw, bh, layout.RADIUS, layout.RADIUS)

        -- rows
        local first = math.max(1, math.floor(st.topf) + 1)
        local last  = math.min(n, math.ceil(st.topf) + per + 1)
        for i = first, last do
            local ry = y + (i - 1 - st.topf) * stride
            local f = util.clamp(1 - math.abs(i - st.pos), 0, 1)
            if o.draw then
                love.graphics.push()
                if f > 0 and bump > 0 then
                    local cx, cy = x + w / 2, ry + rowH / 2
                    love.graphics.translate(cx, cy)
                    love.graphics.scale(1 + bump * f, 1 + bump * f)
                    love.graphics.translate(-cx, -cy)
                end
                o.draw(items[i], x + 12, ry, w - 24, rowH, f >= 0.5, f)
                love.graphics.pop()
            end
        end
    else
        love.graphics.setFont(font.body)
        theme.rgba("text_disabled")
        love.graphics.print(o.empty or "nothing here", x + 12, y + 8)
    end

    if sx then love.graphics.setScissor(sx, sy, sw, sh) else love.graphics.setScissor() end

    -- position bar in the right margin
    if n > per then
        local bx, bw = x + w + 8, list.BAR_W
        theme.rgba("separator")
        love.graphics.rectangle("fill", bx, y, bw, h, 2, 2)
        local th = math.max(18, h * per / n)
        local ty = y + (h - th) * util.clamp(st.topf / math.max(1, n - per), 0, 1)
        theme.rgba("accent")
        love.graphics.rectangle("fill", bx, ty, bw, th, 2, 2)
    end
end })

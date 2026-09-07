-- fskit/ui/list.lua
-- Vertical picker list. Focus row = a static faint bg_panel fill + a 3px accent
-- bar on the left edge (modern minimalist — no gradient, glow or pulse).
-- Scrolls to keep the selection visible. The caller draws each row via
-- drawRow(item, x, y, w, rowH, focused).
--
--   fskit.ui.list(items, sel, {
--     x=, y=, w=, h=,          -- default: fskit.layout.content()
--     rowH = 34,
--     empty = "nothing here",
--     draw = function(item, x, y, w, rowH, focused) ... end,
--   })

local theme  = require("fskit.theme")
local font   = require("fskit.font")
local layout = require("fskit.layout")

return function(items, sel, o)
    o = o or {}
    local cx, cy, cw, ch = layout.content()
    local x    = o.x or cx
    local y    = o.y or cy
    local w    = o.w or cw
    local h    = o.h or ch
    local rowH = o.rowH or 34

    local per = math.max(1, math.floor(h / rowH))
    local top = 1
    if sel > per then top = sel - per + 1 end

    for i = top, math.min(#items, top + per - 1) do
        local ry = y + (i - top) * rowH
        local focused = (i == sel)
        if focused then
            theme.rgba("bg_panel")
            love.graphics.rectangle("fill", x, ry, w, rowH - 2, layout.RADIUS, layout.RADIUS)
            theme.rgba("accent")
            love.graphics.rectangle("fill", x, ry + 2, 3, rowH - 6)
        end
        if o.draw then o.draw(items[i], x + 8, ry, w - 16, rowH, focused) end
    end

    if #items == 0 then
        love.graphics.setFont(font.body)
        theme.rgba("text_disabled")
        love.graphics.print(o.empty or "nothing here", x + 8, y + 4)
    end
end

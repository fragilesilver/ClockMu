-- fskit/ui/themepicker.lua
-- The shared theme screen: the five colours (Mustard, Crimson, Ocean, Funky,
-- Andromeda) as rows with a dark and a light swatch each; the highlighted colour
-- is applied live. Y toggles Dark / Light, A keeps the choice, B puts back the
-- theme that was active when the picker opened.
--
--   local tp = fskit.ui.themepicker.new()          -- in the scene's enter()
--   -- update(dt): tp:update(dt)          draw(): tp:draw()
--   -- input(k):   local r = tp:input(k); if r then <leave the scene> end
--   --   r == "keep" (A) or "cancel" (B, theme restored)
--
-- It draws the whole screen (header, rows, footer); the app only hosts it.

local theme   = require("fskit.theme")
local themes  = require("fskit.themes")
local font    = require("fskit.font")
local screen  = require("fskit.screen")
local layout  = require("fskit.layout")
local motion  = require("fskit.motion")
local header  = require("fskit.ui.header")
local footer  = require("fskit.ui.footer")
local list    = require("fskit.ui.list")

local themepicker = {}
themepicker.__index = themepicker

-- the colour families in order (from themes.lua: the first five are the dark ones)
local FAMILIES = {}
for i = 1, #themes do
    if themes[i].mode == "dark" then FAMILIES[#FAMILIES + 1] = themes[i].family end
end
themepicker.FAMILIES = FAMILIES

local function familyOf(index)
    for i, f in ipairs(FAMILIES) do if f == theme.palette(index).family then return i end end
    return 1
end

function themepicker.new(o)
    o = o or {}
    local self = setmetatable({ orig = theme.index(), title = o.title or "Theme", id = o.id or "themepicker" }, themepicker)
    self.sel = familyOf(self.orig)
    list.reset(self.id)
    return self
end

function themepicker:update(dt) end    -- the list glides from the clock; nothing to advance

function themepicker:_apply()
    local mode = theme.mode()
    theme.set(theme.familyIndex(FAMILIES[self.sel], mode) or theme.index())
end

-- returns "keep", "cancel" or nil
function themepicker:input(k)
    local n = list.nav(self.sel, k, #FAMILIES, list.pageSize{ h = self:_listH() })
    if n then self.sel = n; self:_apply(); return nil end
    if k == "y" then theme.toggleMode(); return nil end
    if k == "a" then return "keep" end
    if k == "b" then theme.set(self.orig); return "cancel" end
end

function themepicker:_listH()
    local _, y, _, h = layout.content()
    return h - 50                                     -- minus the Dark / Light switch
end

local function swatch(x, y, size, idx)
    local p = theme.palette(idx)
    local r = 5
    love.graphics.setColor(p.bg_main[1], p.bg_main[2], p.bg_main[3])
    love.graphics.rectangle("fill", x, y, size, size, r, r)
    love.graphics.setColor(p.accent[1], p.accent[2], p.accent[3])
    love.graphics.polygon("fill", x + size, y, x + size, y + size, x, y + size)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.55)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, size - 1, size - 1, r, r)
end

function themepicker:draw()
    local W, H = screen.W, screen.H
    theme.rgba("bg_main"); love.graphics.rectangle("fill", 0, 0, W, H)
    header.draw{ title = self.title, right = theme.name() }

    local cx, cy, cw, ch = layout.content()
    -- Dark / Light switch
    local sh = 40
    local half = (cw - 8) / 2
    for i, m in ipairs({ "dark", "light" }) do
        local x = cx + (i - 1) * (half + 8)
        local on = theme.mode() == m
        theme.rgba(on and "accent" or "bg_panel")
        love.graphics.rectangle("fill", x, cy, half, sh, layout.RADIUS, layout.RADIUS)
        love.graphics.setFont(font.md)
        theme.rgba(on and "on_accent" or "text_secondary")
        local label = m == "dark" and "Dark" or "Light"
        love.graphics.print(label, x + (half - font.md:getWidth(label)) / 2, cy + (sh - font.md:getHeight()) / 2)
    end

    local items = {}
    for i, f in ipairs(FAMILIES) do items[i] = f end
    list(items, self.sel, {
        id = self.id, x = cx, y = cy + sh + 10, w = cw, h = ch - sh - 10,
        draw = function(name, x, y, w, rowH, focused)
            love.graphics.setFont(font.md)
            theme.rgba(focused and "on_accent" or "text_primary")
            love.graphics.print(name, x, y + (rowH - font.md:getHeight()) / 2)
            local sz = 24
            local sx = x + w - sz * 2 - 10
            for j, m in ipairs({ "dark", "light" }) do
                swatch(sx + (j - 1) * (sz + 10), y + (rowH - sz) / 2, sz, theme.familyIndex(name, m))
            end
        end,
    })

    footer.draw{
        { icon = "a", label = "Keep" }, { icon = "y", label = "Dark / Light" },
        { icon = "b", label = "Back", side = "right" },
    }
end

return themepicker

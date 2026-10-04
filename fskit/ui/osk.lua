-- fskit/ui/osk.lua
-- On-screen keyboard, Andromeda style: a full-screen overlay (header, text field,
-- keys, footer) with two pages:
--   ABC  digits, letters, ' - . &       (SHIFT capitalises the next letter)
--   SYM  digits and every ASCII symbol  ! @ # $ % ^ & * ( ) - _ = + [ ] { } ; :
--                                       ' " , . < > / ? \ | ~ `
-- The focused key is a solid accent block that glides; a typed key flashes and
-- squishes. Based on ScrapMu's keyboard (first used for the refine search).
--
--   fskit.ui.osk.open{ title = "Alarm label", text = "Gym", max = 32, mask = false,
--                      onDone = function(text) end, onCancel = function() end }
--
-- Buttons: d-pad moves · A types the key · X deletes · Y shift · L1/R1 other page ·
--          START (or the OK key) accepts · B cancels.
--
-- osk.new{...} builds the keyboard without registering it as the scene overlay
-- (tests, or an app that wants to embed it); it has :input(b) :update(dt) :draw().

local theme   = require("fskit.theme")
local font    = require("fskit.font")
local screen  = require("fskit.screen")
local layout  = require("fskit.layout")
local motion  = require("fskit.motion")
local scenes  = require("fskit.scene")
local header  = require("fskit.ui.header")
local footer  = require("fskit.ui.footer")
local util    = require("fskit.ui.util")

local osk = {}

osk.MAX = 32
local GAP = 6

local function chars(s) local t = {}; for ch in s:gmatch(".") do t[#t + 1] = ch end; return t end

-- rows of single keys, then the bottom row of { label, span } controls (spans add to 10)
local PAGES = {
    abc = {
        rows = { chars("1234567890"), chars("qwertyuiop"), chars("asdfghjkl'"), chars("zxcvbnm-.&") },
        bottom = { { "SHIFT", 2 }, { "SYM", 2 }, { "SPACE", 3 }, { "DEL", 1.5 }, { "OK", 1.5 } },
    },
    sym = {
        rows = { chars("1234567890"), chars("!@#$%^&*()"), chars("-_=+[]{};:"), chars([['",.<>/?\|]]) },
        bottom = { { "ABC", 2 }, { "~", 1 }, { "`", 1 }, { "SPACE", 3 }, { "DEL", 1.5 }, { "OK", 1.5 } },
    },
}
osk.PAGES = PAGES

-- the keys of one page as a flat list per row: { label, span, u0 } (u0 = start, in units)
local function pageRows(page)
    local p = PAGES[page]
    local rows = {}
    for r, row in ipairs(p.rows) do
        local keys = {}
        for c, ch in ipairs(row) do keys[c] = { label = ch, span = 1, u0 = c - 1 } end
        rows[r] = keys
    end
    local keys, u = {}, 0
    for c, k in ipairs(p.bottom) do keys[c] = { label = k[1], span = k[2], u0 = u }; u = u + k[2] end
    rows[#rows + 1] = keys
    return rows
end

-- key rectangles for a screen of w x h: geom.keys[page][r][c] = { x, y, w, h }
function osk.geometry(w, h, hdr, ftr)
    w, h = w or screen.W, h or screen.H
    hdr, ftr = hdr or layout.HDR_H, ftr or layout.FOOTER_H
    local x0 = layout.PAD
    local total = w - 2 * x0
    local unit = (total + GAP) / 10 - GAP
    local fieldY, fieldH = hdr + 12, 52
    local keysY = fieldY + fieldH + 12
    local avail = h - ftr - 8 - keysY
    local keyH = util.clamp(math.floor((avail - 4 * GAP) / 5), 30, 76)
    local g = { field = { x0, fieldY, total, fieldH }, keyH = keyH, keysY = keysY, keys = {} }
    for page in pairs(PAGES) do
        g.keys[page] = {}
        for r, row in ipairs(pageRows(page)) do
            g.keys[page][r] = {}
            for c, k in ipairs(row) do
                g.keys[page][r][c] = {
                    x = x0 + k.u0 * (unit + GAP), y = keysY + (r - 1) * (keyH + GAP),
                    w = k.span * (unit + GAP) - GAP, h = keyH, label = k.label,
                }
            end
        end
    end
    g.bottom = keysY + 5 * keyH + 4 * GAP
    return g
end

function osk.new(opts)
    opts = opts or {}
    local self = {
        text = opts.text or "", page = "abc", shift = false, r = 2, c = 1,
        t = 0, flash = {}, accepted = false, cancelled = false,
    }
    local max = opts.max or osk.MAX
    self.rows = { abc = pageRows("abc"), sym = pageRows("sym") }

    local function key() return self.rows[self.page][self.r][self.c] end

    local function type_(ch) if #self.text < max then self.text = self.text .. ch end end
    local function backspace() self.text = self.text:gsub("[%z\1-\127\194-\244][\128-\191]*$", "") end

    local function setPage(p)
        self.page = p
        self.r = util.clamp(self.r, 1, 5)
        self.c = util.clamp(self.c, 1, #self.rows[p][self.r])
    end

    -- the key in row r2 whose centre is nearest to the focused key's centre
    local function nearest(r2)
        local k = key()
        local cx = k.u0 + k.span / 2
        local best, bd = 1, math.huge
        for c, kk in ipairs(self.rows[self.page][r2]) do
            local d = math.abs((kk.u0 + kk.span / 2) - cx)
            if d < bd then best, bd = c, d end
        end
        return best
    end

    local function press(label, flashId)
        self.flash[flashId or label] = 1
        if label == "OK" then self.accepted = true; if opts.onDone then opts.onDone(self.text) end
        elseif label == "DEL" then backspace()
        elseif label == "SPACE" then type_(" ")
        elseif label == "SHIFT" then self.shift = not self.shift
        elseif label == "SYM" then setPage("sym")
        elseif label == "ABC" then setPage("abc")
        else
            type_((self.page == "abc" and self.shift) and label:upper() or label)
            self.shift = false
        end
    end

    function self:input(b)
        local rows = self.rows[self.page]
        if b == "up" then local r2 = (self.r - 2) % #rows + 1; self.c = nearest(r2); self.r = r2
        elseif b == "down" then local r2 = self.r % #rows + 1; self.c = nearest(r2); self.r = r2
        elseif b == "left" then self.c = (self.c - 2) % #rows[self.r] + 1
        elseif b == "right" then self.c = self.c % #rows[self.r] + 1
        elseif b == "a" then press(key().label, self.page .. self.r .. "," .. self.c)
        elseif b == "x" then self.flash.DEL = 1; backspace()
        elseif b == "y" then if self.page == "abc" then self.flash.SHIFT = 1; self.shift = not self.shift end
        elseif b == "l1" or b == "r1" then setPage(self.page == "abc" and "sym" or "abc")
        elseif b == "start" then press("OK")
        elseif b == "b" then self.cancelled = true; if opts.onCancel then opts.onCancel() end
        end
    end

    -- the label a key shows right now
    function self:labelOf(k)
        if self.page == "abc" and self.shift and #k.label == 1 then return k.label:upper() end
        return k.label
    end

    function self:update(dt)
        self.t = self.t + (dt or 0)
        for id, v in pairs(self.flash) do
            v = v - (dt or 0) * 6.5
            self.flash[id] = v > 0 and v or nil
        end
        -- focus block glides to the focused key
        local g = osk.geometry()
        local k = g.keys[self.page][self.r][self.c]
        if not self.hx or not motion.enabled then
            self.hx, self.hy, self.hw, self.hh = k.x, k.y, k.w, k.h
        else
            local rate = 30
            self.hx = motion.approach(self.hx, k.x, rate, dt)
            self.hy = motion.approach(self.hy, k.y, rate, dt)
            self.hw = motion.approach(self.hw, k.w, rate, dt)
            self.hh = motion.approach(self.hh, k.h, rate, dt)
        end
    end

    function self:draw()
        local W, H = screen.W, screen.H
        theme.rgba("bg_main"); love.graphics.rectangle("fill", 0, 0, W, H)
        header.draw{ title = opts.title or "Enter text",
            right = self.page == "sym" and "SYM" or (self.shift and "ABC" or "abc") }

        local g = osk.geometry()
        -- text field
        local fx, fy, fw, fh = unpack(g.field)
        util.barred(fx, fy, fw, fh, layout.BAR, layout.RADIUS, "accent", "bg_panel")
        local shown = opts.mask and string.rep("*", #self.text) or self.text
        local tf = font.lg
        love.graphics.setFont(tf)
        local tx, tw = fx + layout.BAR + 14, fw - layout.BAR - 28
        local sx, sy, sw, sh = love.graphics.getScissor()
        love.graphics.intersectScissor(tx, fy, tw, fh)
        local textW = tf:getWidth(shown)
        local px = tx + math.min(0, tw - textW - 6)
        theme.rgba("text_primary")
        love.graphics.print(shown, px, fy + (fh - tf:getHeight()) / 2)
        if motion.pulse(6) > 0.4 then
            theme.rgba("accent")
            love.graphics.rectangle("fill", px + textW + 3, fy + 11, 2, fh - 22)
        end
        if sx then love.graphics.setScissor(sx, sy, sw, sh) else love.graphics.setScissor() end

        -- keys: caps first, then the gliding focus block, then labels
        local kg = g.keys[self.page]
        for r, row in ipairs(kg) do
            for c, k in ipairs(row) do
                local f = self.flash[self.page .. r .. "," .. c] or self.flash[k.label] or 0
                local sc = 1 - 0.10 * f
                local cx, cy = k.x + k.w / 2, k.y + k.h / 2
                love.graphics.push()
                love.graphics.translate(cx, cy); love.graphics.scale(sc, sc); love.graphics.translate(-cx, -cy)
                local special = #k.label > 1
                local on = (k.label == "SHIFT" and self.shift)
                theme.rgba(on and "accent" or (special and "bg_header" or "bg_panel"))
                love.graphics.rectangle("fill", k.x, k.y, k.w, k.h, layout.RADIUS, layout.RADIUS)
                love.graphics.pop()
            end
        end
        if self.hx then
            local f = (self.flash[self.page .. self.r .. "," .. self.c] or self.flash[self.rows[self.page][self.r][self.c].label] or 0)
            local sc = 1 - 0.10 * f
            local cx, cy = self.hx + self.hw / 2, self.hy + self.hh / 2
            love.graphics.push()
            love.graphics.translate(cx, cy); love.graphics.scale(sc, sc); love.graphics.translate(-cx, -cy)
            theme.rgba(f > 0.3 and "accent_glow" or "accent")
            love.graphics.rectangle("fill", self.hx, self.hy, self.hw, self.hh, layout.RADIUS, layout.RADIUS)
            love.graphics.pop()
        end
        for r, row in ipairs(kg) do
            for c, k in ipairs(row) do
                local focused = (r == self.r and c == self.c)
                local special = #k.label > 1
                love.graphics.setFont(special and font.sm or font.md)
                local label = self:labelOf(k)
                if label == "SPACE" then label = "Space" elseif label == "DEL" then label = "Del"
                elseif label == "SHIFT" then label = "Shift" end
                local role = focused and "on_accent" or ((k.label == "SHIFT" and self.shift) and "on_accent" or (special and "text_secondary" or "text_primary"))
                theme.rgba(role)
                local f = love.graphics.getFont()
                love.graphics.print(label, k.x + (k.w - f:getWidth(label)) / 2, k.y + (k.h - f:getHeight()) / 2)
            end
        end

        footer.draw{
            { icon = "a", label = "Type" }, { icon = "x", label = "Del" }, { icon = "y", label = "Shift" },
            { icon = "l1", label = "Page" }, { icon = "start", label = "Done" },
            { icon = "b", label = "Cancel", side = "right" },
        }
    end

    return self
end

function osk.open(opts)
    opts = opts or {}
    local user_done, user_cancel = opts.onDone, opts.onCancel
    local o = {}
    for k, v in pairs(opts) do o[k] = v end
    o.onDone = function(text) scenes.clearOverlay(); if user_done then user_done(text) end end
    o.onCancel = function() scenes.clearOverlay(); if user_cancel then user_cancel() end end
    local kb = osk.new(o)
    local overlay = { input = function(b) kb:input(b) end, update = function(dt) kb:update(dt) end,
                      draw = function() kb:draw() end, keyboard = kb }
    scenes.setOverlay(overlay)
    return overlay
end

return osk

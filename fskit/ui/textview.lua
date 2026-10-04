-- fskit/ui/textview.lua
-- Wrapped, scrollable text (descriptions, help, health info). Smooth scroll, a
-- slim position bar, and the button contract: up/down one line, L1/R1 one page,
-- L2/R2 jump to the start / end.
--
--   local tv = fskit.ui.textview.new{ font = fskit.font.body, role = "text_secondary" }
--   tv:set("long text ...")
--   -- in input:   if tv:input(k) then return end
--   -- in draw:    tv:draw(x, y, w, h)
--
-- The first draw after set() starts at the top. With reduce-motion on the scroll
-- is instant.

local theme  = require("fskit.theme")
local font   = require("fskit.font")
local motion = require("fskit.motion")
local util   = require("fskit.ui.util")

local textview = {}
textview.__index = textview

textview.SCROLL = 18     -- how fast the view chases its target (1/s)
textview.BAR    = 4

function textview.new(o)
    o = o or {}
    return setmetatable({
        text = "", font = o.font, role = o.role or "text_secondary", empty = o.empty,
        target = 0, pos = 0, t = motion.time(), w = 0, h = 0, lines = nil, lineH = 0,
    }, textview)
end

function textview:set(text)
    self.text = text or ""
    self.lines, self.target, self.pos = nil, 0, 0
end

-- wrap lazily for the width we are drawn at
function textview:_wrap(w)
    local f = self.font or font.body
    if self.lines and self.wrapW == w and self.wrapFont == f then return end
    local _, lines = f:getWrap(self.text ~= "" and self.text or " ", w)
    self.lines, self.wrapW, self.wrapFont = lines, w, f
    self.lineH = f:getHeight() * f:getLineHeight()
end

function textview:contentHeight() return self.lines and (#self.lines * self.lineH) or 0 end
function textview:maxScroll() return math.max(0, self:contentHeight() - self.h) end

-- handle a button; true if it was a scroll key
function textview:input(k)
    local step = (self.lineH > 0 and self.lineH or 18)
    local page = math.max(step, self.h - step)
    local t = self.target
    if k == "up" then t = t - step
    elseif k == "down" then t = t + step
    elseif k == "l1" then t = t - page
    elseif k == "r1" then t = t + page
    elseif k == "l2" then t = 0
    elseif k == "r2" then t = self:maxScroll()
    else return false end
    self.target = util.clamp(t, 0, self:maxScroll())
    return true
end

function textview:draw(x, y, w, h)
    self.w, self.h = w, h
    local f = self.font or font.body
    local barRoom = self.BAR + 8
    self:_wrap(w - barRoom)
    local now = motion.time()
    local dt = now - self.t
    self.t = now
    self.target = util.clamp(self.target, 0, self:maxScroll())
    self.pos = motion.approach(self.pos, self.target, textview.SCROLL, dt)

    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.intersectScissor(x, y, w, h)
    love.graphics.setFont(f)
    if self.text == "" and self.empty then
        theme.rgba("text_disabled")
        love.graphics.print(self.empty, x, y)
    else
        theme.rgba(self.role)
        local first = math.max(1, math.floor(self.pos / self.lineH))
        local last = math.min(#self.lines, math.ceil((self.pos + h) / self.lineH) + 1)
        for i = first, last do
            love.graphics.print(self.lines[i], x, y + (i - 1) * self.lineH - self.pos)
        end
    end
    if sx then love.graphics.setScissor(sx, sy, sw, sh) else love.graphics.setScissor() end

    local total = self:contentHeight()
    if total > h then
        local bx = x + w - self.BAR
        theme.rgba("separator")
        love.graphics.rectangle("fill", bx, y, self.BAR, h, 2, 2)
        local th = math.max(18, h * h / total)
        local ty = y + (h - th) * util.clamp(self.pos / math.max(1, total - h), 0, 1)
        theme.rgba("accent")
        love.graphics.rectangle("fill", bx, ty, self.BAR, th, 2, 2)
    end
end

return textview

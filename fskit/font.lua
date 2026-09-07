-- fskit/font.lua
-- Shared family (Bold.ttf / Regular.ttf — byte-identical across ClockMu &
-- BatteryMu; JarMu adopts it). Canonical size names plus back-compat aliases so
-- both the ClockMu-era (big/med/sm/xs/body) and SwapMu-era
-- (huge/xl/lg/md/sm/xs/body/body_xs) call sites keep working.

local DIR = "fskit/assets/font/"

local font = {}

function font.load()
    local B, R = DIR .. "Bold.ttf", DIR .. "Regular.ttf"

    font.clock   = love.graphics.newFont(B, 64)   -- opt-in, ClockMu big readout
    font.huge    = love.graphics.newFont(B, 36)
    font.xl      = love.graphics.newFont(B, 22)
    font.lg      = love.graphics.newFont(B, 18)
    font.md      = love.graphics.newFont(B, 14)
    font.sm      = love.graphics.newFont(B, 12)
    font.xs      = love.graphics.newFont(B, 10)
    font.body    = love.graphics.newFont(R, 12)
    font.body_lg = love.graphics.newFont(R, 16)
    font.body_xs = love.graphics.newFont(R, 10)

    -- canonical aliases from the spec / per-app history
    font.big     = font.huge
    font.med     = font.xl
    font.body_sm = font.body_xs

    for _, f in pairs(font) do
        if type(f) == "userdata" then f:setFilter("linear", "linear") end
    end
end

-- 1px shadowed text, mirroring muOS's shadowed labels
function font.print(text, x, y, r, g, b, a)
    love.graphics.setColor(0, 0, 0, (a or 1) * 0.55)
    love.graphics.print(text, x + 1, y + 1)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.print(text, x, y)
end

return font

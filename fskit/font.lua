-- fskit/font.lua
-- Shared type family + a small size scale. Sizes are tuned for the 640x480
-- virtual canvas (fskit.screen), so they never need per-device adjustment.

local DIR = "fskit/assets/font/"

local font = {}

function font.load()
    local B = DIR .. "Bold.ttf"
    local R = DIR .. "Regular.ttf"

    font.clock    = love.graphics.newFont(B, 54)   -- the big HH:MM
    font.big      = love.graphics.newFont(B, 20)
    font.med      = love.graphics.newFont(B, 15)
    font.sm       = love.graphics.newFont(B, 13)
    font.xs       = love.graphics.newFont(B, 11)

    font.body_lg  = love.graphics.newFont(R, 18)
    font.body     = love.graphics.newFont(R, 14)
    font.body_sm  = love.graphics.newFont(R, 11)

    for _, f in pairs(font) do
        if type(f) == "userdata" then f:setFilter("linear", "linear") end
    end
end

return font

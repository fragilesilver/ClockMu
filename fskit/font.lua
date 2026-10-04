-- fskit/font.lua
-- Andromeda type (docs/andromeda-design.md §3). Barlow (SIL OFL, bundled with
-- Barlow-OFL.txt) for everything, Barlow Condensed ExtraBold for display text,
-- Noto Sans as the automatic fallback for scripts Barlow lacks (Cyrillic,
-- Greek, ...), so a non-Latin alarm label or game name still shows.
--
-- Old names keep working: big = huge, med = xl, body_sm = body_xs.

local DIR = "fskit/assets/font/"

local font = {}

local function make(file, size, fallback)
    local f = love.graphics.newFont(DIR .. file, size)
    if fallback then
        local ok, fb = pcall(love.graphics.newFont, DIR .. fallback, size)
        if ok and f.setFallbacks then f:setFallbacks(fb) end
    end
    return f
end

function font.load()
    local DISPLAY, BOLD, REG = "BarlowCondensed-ExtraBold.ttf", "Barlow-SemiBold.ttf", "Barlow-Medium.ttf"
    local NB, NR = "Bold.ttf", "Regular.ttf"                 -- Noto Sans

    font.clock    = make(NB, 64)                             -- ClockMu readout: Noto's tabular digits
    font.huge     = make(DISPLAY, 40, NB)                    -- big readouts (battery %)
    font.xl       = make(DISPLAY, 28, NB)                    -- header title
    font.dlg      = make(DISPLAY, 24, NB)                    -- dialog title
    font.lg       = make(BOLD, 18, NB)
    font.md       = make(BOLD, 16, NB)
    font.sm       = make(BOLD, 14, NB)
    font.xs       = make(BOLD, 12, NB)
    font.body_lg  = make(REG, 18, NR)
    font.body     = make(REG, 15, NR)
    font.body_xs  = make(REG, 12, NR)

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

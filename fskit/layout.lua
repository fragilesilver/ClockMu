-- fskit/layout.lua
-- One place for the screen geometry. Everything routes through these, and they
-- follow the screen profile (see fskit/screen.lua), so no app or widget hard-codes
-- 640 or 480. The values are the Andromeda design tokens (docs/andromeda-design.md):
--
--   profile   header  footer  row    cards across
--   standard   58      48      44      2
--   wide       58      48      44      4
--   square     64      56      48      2
--
-- Read fields at draw time (or once after require): they are updated in place
-- when the profile changes, and `layout.SW/SH` are the canvas size.

local screen = require("fskit.screen")

local layout = {}

local METRICS = {
    standard = { HDR_H = 58, FOOTER_H = 48, ROW_H = 44, COLUMNS = 2 },
    wide     = { HDR_H = 58, FOOTER_H = 48, ROW_H = 44, COLUMNS = 4 },
    square   = { HDR_H = 64, FOOTER_H = 56, ROW_H = 48, COLUMNS = 2 },
}

layout.PAD        = 16                     -- side margin of content
layout.GAP        = 12                     -- space between content blocks
layout.ROW_GAP    = 4
layout.RADIUS     = 6                      -- row / button / card corner
layout.BAR        = 6                      -- accent bar on the left of a card
layout.DLG_RADIUS = 8
layout.DLG_BAR    = 8                      -- accent bar on top of a dialog
layout.SHADOW     = { 0, 0, 0, 0.35 }

local function update(w, h, profile)
    layout.SW, layout.SH, layout.profile = w, h, profile
    for k, v in pairs(METRICS[profile] or METRICS.standard) do layout[k] = v end
end
screen.onChange(update)

function layout.headerRect() return 0, 0, layout.SW, layout.HDR_H end
function layout.footerRect() return 0, layout.SH - layout.FOOTER_H, layout.SW, layout.FOOTER_H end

-- x, y, w, h of the area between header and footer
function layout.content()
    local y = layout.HDR_H + layout.GAP
    return layout.PAD, y, layout.SW - layout.PAD * 2, layout.SH - layout.FOOTER_H - 8 - y
end

-- how many rows of height rowH (with ROW_GAP between) fit in h
function layout.rows(h, rowH)
    rowH = rowH or layout.ROW_H
    return math.max(1, math.floor((h + layout.ROW_GAP) / (rowH + layout.ROW_GAP)))
end

return layout

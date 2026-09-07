-- fskit/ui/dialog.lua
-- Modal confirm card: dim scrim, centred bg_panel card, static crisp border in
-- `tone`, A=confirm / B=cancel button block. Registers itself as the scene
-- overlay so it draws over the frozen scene and eats input until dismissed.
--
--   fskit.ui.dialog.open{
--     title = "Exit ClockMu?", body = "Are you sure you want to quit?",
--     confirm = "Quit", cancel = "Cancel", tone = "accent",
--     onConfirm = function() love.event.quit() end,
--     onCancel  = function() end,
--   }

local theme  = require("fskit.theme")
local font   = require("fskit.font")
local glyph  = require("fskit.glyph")
local screen = require("fskit.screen")
local layout = require("fskit.layout")
local scenes = require("fskit.scene")

local dialog = {}

local function close(self, run)
    scenes.clearOverlay()
    if run and self._cb then self._cb() end
end

function dialog.open(opts)
    opts = opts or {}
    local self = { _cb = nil }
    local onConfirm, onCancel = opts.onConfirm, opts.onCancel

    function self.input(button)
        if button == "a" then
            close(self); if onConfirm then onConfirm() end
        elseif button == "b" then
            close(self); if onCancel then onCancel() end
        end
    end

    function self.draw()
        local SW, SH = screen.W, screen.H
        theme.rgba("bg_main", 0.62)
        love.graphics.rectangle("fill", 0, 0, SW, SH)

        local dw, dh = 340, 156
        local dx, dy = SW / 2 - dw / 2, SH / 2 - dh / 2
        local tone = opts.tone or "accent"

        theme.rgba("bg_panel")
        love.graphics.rectangle("fill", dx, dy, dw, dh, 10, 10)
        theme.rgba(tone)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", dx + 1, dy + 1, dw - 2, dh - 2, 10, 10)

        if opts.title then
            love.graphics.setFont(font.xl)
            local tw = font.xl:getWidth(opts.title)
            theme.rgba(tone == "accent" and "accent_glow" or tone)
            love.graphics.print(opts.title, SW / 2 - tw / 2, dy + 20)
        end
        if opts.body then
            love.graphics.setFont(font.sm)
            local bw = font.sm:getWidth(opts.body)
            theme.rgba("text_secondary")
            love.graphics.print(opts.body, SW / 2 - bw / 2, dy + 54)
        end

        -- buttons
        local bw, bh, gap = 120, 38, 20
        local total = bw * 2 + gap
        local by = dy + dh - bh - 16
        local cancelX = SW / 2 - total / 2
        local okX = cancelX + bw + gap

        theme.rgba("bg_main")
        love.graphics.rectangle("fill", cancelX, by, bw, bh, 6, 6)
        theme.rgba("separator")
        love.graphics.rectangle("line", cancelX, by, bw, bh, 6, 6)
        theme.rgba("accent")
        love.graphics.rectangle("fill", okX, by, bw, bh, 6, 6)

        local function btn(gx, gname, label, labelRole)
            local g = glyph.get(gname)
            local lx = gx + 12
            if g then
                local s = glyph.scaleFor(gname)
                theme.rgba("text_primary")
                love.graphics.draw(g, gx + 10, by + (bh - g:getHeight() * s) / 2, 0, s, s)
                lx = gx + 10 + g:getWidth() * s + 6
            end
            love.graphics.setFont(font.sm)
            theme.rgba(labelRole)
            love.graphics.print(label, lx, by + (bh - font.sm:getHeight()) / 2)
        end
        btn(cancelX, "b", opts.cancel or "Cancel", "text_secondary")
        btn(okX, "a", opts.confirm or "OK", "bg_main")
    end

    scenes.setOverlay(self)
    return self
end

return dialog

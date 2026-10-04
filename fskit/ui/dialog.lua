-- fskit/ui/dialog.lua
-- Modal confirm card, Andromeda style: dim scrim, a centred bg_panel card with an
-- 8 px bar of the tone colour along its top, the title in display type, and two
-- buttons: B (cancel, secondary) and A (confirm, filled). A confirms, B cancels.
-- The glyph in each button reacts to its physical button like the footer's.
--
--   fskit.ui.dialog.open{
--     title = "Quit ClockMu?", body = "Alarms only ring while ClockMu is open.",
--     confirm = "Quit", cancel = "Stay", tone = "warn",      -- tone: accent | warn | danger
--     onConfirm = function() love.event.quit() end,
--     onCancel  = function() end,
--   }
--   fskit.ui.dialog.confirmExit("ClockMu")      -- the standard "Quit <App>?"
--
-- The card is sized to its text (never under its buttons): taller for each body
-- line, wider for a long title or line, up to the screen's safe area.
-- Registers itself as the scene overlay: it draws over the frozen scene and eats
-- input until dismissed. For an engine without fskit.scene (JarMu):
--   local st = dialog.state()
--   each frame: dialog.update(st, dt); dialog.render(opts, st)
--   on a button: A -> confirm, B -> cancel (you handle your own input)

local theme   = require("fskit.theme")
local font    = require("fskit.font")
local glyph   = require("fskit.glyph")
local screen  = require("fskit.screen")
local layout  = require("fskit.layout")
local scenes  = require("fskit.scene")
local motion  = require("fskit.motion")
local input   = require("fskit.input")
local util    = require("fskit.ui.util")
local marquee = require("fskit.ui.marquee")
local footer  = require("fskit.ui.footer")

local dialog = {}

dialog.BTN_H   = 40
dialog.PAD     = 22
dialog.MIN_W   = 360

-- Card geometry for these opts, from the real font metrics. body_end must not
-- pass by (the buttons' top); tests check exactly that at every screen size.
function dialog.geometry(opts)
    local SW, SH = screen.W, screen.H
    local lines = {}
    if opts.body then
        for line in (opts.body .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
    end
    local tf, bf = font.dlg, font.body
    local th = opts.title and tf:getHeight() or 0
    local lh = bf:getHeight()
    local pad = dialog.PAD
    local bar = layout.DLG_BAR

    local body_h = #lines * lh
    local dh = bar + pad + th + (th > 0 and body_h > 0 and 8 or 0) + body_h
        + ((th > 0 or body_h > 0) and 16 or 0) + dialog.BTN_H + pad - 4
    local want = dialog.MIN_W
    if opts.title then want = math.max(want, tf:getWidth(opts.title:upper()) + pad * 2) end
    for _, line in ipairs(lines) do want = math.max(want, bf:getWidth(line) + pad * 2) end
    local safe = screen.SAFE
    local dw = math.min(want, SW - 2 * safe)
    dh = math.min(dh, SH - 2 * safe)
    local dx, dy = (SW - dw) / 2, (SH - dh) / 2

    local title_y = dy + bar + pad
    local body_y = title_y + th + (th > 0 and 8 or 0)
    return { dw = dw, dh = dh, dx = dx, dy = dy, lines = lines, lh = lh, bh = dialog.BTN_H,
             title_y = title_y, body_y = body_y, body_end = body_y + body_h,
             by = dy + dh - pad + 4 - dialog.BTN_H }
end

-- animation state for one dialog
function dialog.state()
    return { t = 0, a = { pos = 0, vel = 0, t = motion.time() }, b = { pos = 0, vel = 0, t = motion.time() } }
end

function dialog.update(st, dt)
    st.t = st.t + (dt or 0)
    motion.spring(st.a, input.isShown("a") and 1 or 0, dt or 0)
    motion.spring(st.b, input.isShown("b") and 1 or 0, dt or 0)
end

local TONES = { accent = "accent", warn = "warn", danger = "danger" }

-- one button: fill/label colours, a reacting glyph, centred label
local function button(label, icon, x, y, w, h, fillRole, textRole, spring)
    local p = spring and spring.pos or 0
    local k = 1 - 0.05 * p                                   -- the whole button dips a little
    local cx, cy = x + w / 2, y + h / 2
    love.graphics.push()
    love.graphics.translate(cx, cy); love.graphics.scale(k, k); love.graphics.translate(-cx, -cy)
    theme.rgba(fillRole)
    love.graphics.rectangle("fill", x, y, w, h, layout.RADIUS, layout.RADIUS)

    local f = font.md
    love.graphics.setFont(f)
    local g = glyph.get(icon)
    local gw = 0
    if g then gw = glyph.scaleFor(icon) * g:getWidth() + 8 end
    local total = gw + f:getWidth(label)
    local lx = x + (w - total) / 2
    if g then
        local sc = glyph.scaleFor(icon)
        local gx, gy = lx + g:getWidth() * sc / 2, cy
        theme.rgba(textRole)
        love.graphics.draw(g, gx, gy, 0, sc * (1 - footer.SQUISH_X * p), sc * (1 - footer.SQUISH_Y * p),
            g:getWidth() / 2, g:getHeight() / 2)
    end
    theme.rgba(textRole)
    love.graphics.print(label, lx + gw, cy - f:getHeight() / 2)
    love.graphics.pop()
end

-- draw the dialog (scrim, card, buttons) for opts and animation state st
function dialog.render(opts, st)
    local SW, SH = screen.W, screen.H
    st = st or dialog.state()
    local rise = 1 - motion.progress(st.t, 0.16)              -- 1 -> 0 over 160 ms
    theme.rgba("bg_main", 0.66 * (1 - rise * 0.6))
    love.graphics.rectangle("fill", 0, 0, SW, SH)

    local g = dialog.geometry(opts)
    local dx, dy, dw, dh = g.dx, g.dy + rise * 10, g.dw, g.dh
    local toneRole = TONES[opts.tone or "accent"] or "accent"

    -- card with the tone bar along the top
    theme.rgba(toneRole)
    love.graphics.rectangle("fill", dx, dy, dw, layout.DLG_BAR + layout.DLG_RADIUS, layout.DLG_RADIUS, layout.DLG_RADIUS)
    theme.rgba("bg_panel")
    love.graphics.rectangle("fill", dx, dy + layout.DLG_BAR, dw, dh - layout.DLG_BAR, layout.DLG_RADIUS, layout.DLG_RADIUS)

    local off = dy - g.dy
    if opts.title then
        love.graphics.setFont(font.dlg)
        theme.rgba(toneRole == "accent" and "accent_glow" or toneRole)
        local up = opts.title:upper()
        marquee(up, dx + dialog.PAD, g.title_y + off, dw - dialog.PAD * 2,
            { font = font.dlg, active = true, align = "center" })
    end
    if #g.lines > 0 then
        love.graphics.setFont(font.body)
        theme.rgba("text_secondary")
        local ly = g.body_y + off
        for _, line in ipairs(g.lines) do
            marquee(line, dx + dialog.PAD, ly, dw - dialog.PAD * 2,
                { active = true, align = "center", font = font.body })
            ly = ly + g.lh
        end
    end

    -- buttons: B (secondary, left) and A (filled, right)
    local gap = 12
    local bw = (dw - dialog.PAD * 2 - gap) / 2
    local by = g.by + off
    local confirmRole = toneRole
    button(opts.cancel or "Cancel", "b", dx + dialog.PAD, by, bw, g.bh, "bg_header", "text_primary", st.b)
    button(opts.confirm or "OK", "a", dx + dialog.PAD + bw + gap, by, bw, g.bh, confirmRole,
        util.readable(confirmRole), st.a)
end

local function close() scenes.clearOverlay() end

function dialog.open(opts)
    opts = opts or {}
    local self = {}
    local st = dialog.state()
    local onConfirm, onCancel = opts.onConfirm, opts.onCancel

    function self.input(button)
        if button == "a" then
            close(); if onConfirm then onConfirm() end
        elseif button == "b" then
            close(); if onCancel then onCancel() end
        end
    end
    function self.update(dt) dialog.update(st, dt) end
    function self.draw() dialog.render(opts, st) end

    scenes.setOverlay(self)
    return self
end

-- the standard "Quit <App>?": A quits, B stays
function dialog.confirmExit(app, o)
    o = o or {}
    return dialog.open{
        title = o.title or ("Quit " .. app .. "?"), body = o.body,
        confirm = o.confirm or "Quit", cancel = o.cancel or "Stay", tone = o.tone or "warn",
        onConfirm = o.onConfirm or function() love.event.quit() end,
        onCancel = o.onCancel,
    }
end

return dialog

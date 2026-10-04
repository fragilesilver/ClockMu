-- ============================================================
-- ClockMu  v2.0.0
-- Alarm clock, up to 5 alarms with snooze. muOS Andromeda 2606.0, RG35XX family
-- (Allwinner H700); layouts for 640x480, 720x480 and 720x720 (only 640x480 is
-- device-tested).
-- UI on fskit 0.3 (Bold muOS-style: docs/andromeda-design.md). The alarm logic
-- (alarm.lua, the once-a-second tick, snooze, storage) is unchanged since 1.0;
-- the presentation was rebuilt: scenes, lists with paging, the shared on-screen
-- keyboard (letters + symbols) and the shared theme picker.
-- ============================================================

local love   = require("love")
local Config = require("config")
local Alarm  = require("alarm")
local fskit  = require("fskit")

local L, T, SC, UI, FN = fskit.layout, fskit.theme, fskit.scene, fskit.ui, fskit.font
local LIST, CARD, MARQ = UI.list, UI.card, UI.marquee

local function setC(role, a) T.rgba(role, a) end
local function rect(mode, x, y, w, h, r) love.graphics.rectangle(mode, x, y, w, h, r or 0, r or 0) end
local function content() return L.content() end
local function head(title, right) UI.header.draw{ title = title, right = right } end
local function foot(items) UI.footer.draw(items) end
-- text on a list row: on_accent on the focus block, else the given role
local function rowC(focused, role, a)
    if focused then setC("on_accent", a) else setC(role, a) end
end

-- ============================================================
-- STATE
-- ============================================================
local alarms   = {}
local selIdx   = 1

-- Edit state
local editAlarm  = nil
local editField  = 1   -- 1=hour 2=min 3=label 4=repeat 5=snooze 6=enabled
local editRepDay = 1

local presetList, presetIdx = {}, 1
local labelSelIdx = 1
local themePicker

-- Ringing
local ringingIdx = nil
local ringTimer  = 0
local ringAge    = 0
local ringFlash  = false
local RING_GUARD = 0.35      -- ignore A/B for a moment, so a button mashed just as it rings can't dismiss it

local alarmSound   = nil
local lastFiredMin = -1

local fClock, fRing      -- the time readouts (Noto: tabular digits)

-- ============================================================
-- ALARM FLOW
-- ============================================================
local function saveEditAlarm()
    if editAlarm._isNew then
        if #alarms < Config.MAX_ALARMS then
            editAlarm._isNew = nil
            table.insert(alarms, editAlarm)
            selIdx = #alarms
        end
    else
        local idx = editAlarm._idx
        editAlarm._idx   = nil
        editAlarm._isNew = nil
        alarms[idx] = editAlarm
    end
    Alarm.SaveAll(alarms)
    SC.go("main")
end

local function buildPresets()
    presetList = {}
    for h = 0, 23 do
        for _, m in ipairs({0, 15, 30, 45}) do
            table.insert(presetList, {hour=h, minute=m})
        end
    end
end

local function tryLoadSound()
    if love.filesystem.getInfo(Config.SOUND_PATH) then
        local ok, src = pcall(love.audio.newSource, Config.SOUND_PATH, "static")
        if ok then alarmSound = src; alarmSound:setLooping(true) end
    end
end
local function startRinging()
    if alarmSound then alarmSound:stop(); alarmSound:play() end
    ringTimer, ringAge, ringFlash = 0, 0, false
end
local function stopRinging()
    if alarmSound then alarmSound:stop() end
end

local function openEdit(a, isNew, idx)
    editAlarm = {
        hour = a.hour, minute = a.minute, label = a.label,
        repeat_days = a.repeat_days, enabled = a.enabled,
        snooze_idx = a.snooze_idx, state = a.state, snooze_until = a.snooze_until,
        _idx = idx, _isNew = isNew or nil,
    }
    editField, editRepDay = 1, 1
    SC.go("edit")
end

local function quitDialog()
    UI.dialog.confirmExit("ClockMu", { body = "Alarms stop when the app closes." })
end

-- ============================================================
-- MAIN SCREEN
-- ============================================================
-- the clock card: time on the left, the date on the right
local function heroGeom()
    local x, y, w = content()
    local sq = L.profile == "square"
    return x, y, w, sq and 120 or 84, sq and 1.3 or 1
end

local function drawHero()
    local x, y, w, h, s = heroGeom()
    CARD.draw(x, y, w, h, { role = "accent" })
    local now = os.date("*t")
    local timeS = string.format("%02d:%02d", now.hour, now.min)
    local tx = x + L.BAR + 18
    love.graphics.push()
    love.graphics.translate(tx, y + (h - fClock:getHeight() * s) / 2)
    love.graphics.scale(s, s)
    love.graphics.setFont(fClock); setC("accent")
    love.graphics.print(timeS, 0, 0)
    love.graphics.pop()

    local rx = x + w - 18
    local day, date = os.date("%A"), os.date("%d %b %Y")
    local dh = FN.dlg:getHeight() + FN.md:getHeight() + 2
    local ty = y + (h - dh) / 2
    love.graphics.setFont(FN.dlg); setC("text_primary")
    love.graphics.print(day, rx - FN.dlg:getWidth(day), ty)
    love.graphics.setFont(FN.md); setC("text_secondary")
    love.graphics.print(date, rx - FN.md:getWidth(date), ty + FN.dlg:getHeight() + 2)
end

local ALARM_ROW = 46
local function alarmOpts()
    local x, y, w, h = heroGeom()
    local _, cy, _, ch = content()
    local ly = y + h + L.GAP
    return { id = "alarms", rowH = ALARM_ROW, y = ly, h = cy + ch - ly,
             empty = "No alarms.  Press Y to add one." }
end

local function drawAlarmRow(a, x, y, w, rowH, focused)
    local mid = y + rowH / 2
    -- time
    love.graphics.setFont(FN.xl)
    if focused then setC("on_accent", a.enabled and 1 or 0.55)
    else setC(a.enabled and "accent" or "text_disabled") end
    love.graphics.print(Alarm.TimeString(a), x, mid - FN.xl:getHeight() / 2)
    local lx = x + FN.xl:getWidth("00:00") + 18

    -- right side: enabled dot, snooze minutes, ZZZ when snoozed
    local dotR = 6
    local dotX = x + w - dotR
    if a.enabled then
        if focused then setC("on_accent") else setC("ok") end
        love.graphics.circle("fill", dotX, mid, dotR)
    elseif focused then
        setC("on_accent", 0.7); love.graphics.setLineWidth(2)
        love.graphics.circle("line", dotX, mid, dotR - 1)
    else
        setC("muted"); love.graphics.circle("fill", dotX, mid, dotR)
    end
    local snooze = Config.SNOOZE_OPTIONS[a.snooze_idx] .. "m"
    local sx = dotX - dotR - 14 - FN.xs:getWidth(snooze)
    love.graphics.setFont(FN.xs)
    rowC(focused, "text_secondary", focused and 0.85 or 1)
    love.graphics.print(snooze, sx, mid - FN.xs:getHeight() / 2)
    local limit = sx - 12
    if a.state == "snoozed" then
        local zx = sx - 10 - FN.xs:getWidth("ZZZ")
        rowC(focused, "discharging")
        love.graphics.print("ZZZ", zx, mid - FN.xs:getHeight() / 2)
        limit = zx - 12
    end

    -- label over repeat
    local bh = FN.md:getHeight() + FN.xs:getHeight()
    local top = mid - bh / 2
    love.graphics.setFont(FN.md); rowC(focused, "text_primary")
    MARQ(a.label, lx, top, limit - lx, { font = FN.md, active = focused })
    love.graphics.setFont(FN.xs); rowC(focused, "text_secondary", focused and 0.85 or 1)
    love.graphics.print(Alarm.RepeatString(a), lx, top + FN.md:getHeight())
end

local MAIN_HINTS = {
    { icon = "a",      label = "Edit"   },
    { icon = "x",      label = "Toggle" },
    { icon = "y",      label = "Add"    },
    { icon = "start",  label = "Delete" },
    { icon = "select", label = "Theme"  },
    { icon = "b",      label = "Quit", side = "right" },
}

local function clampSel()
    if selIdx > #alarms then selIdx = math.max(1, #alarms) end
end

-- ============================================================
-- EDIT SCREEN
-- ============================================================
local EDIT_FIELDS = {"Hour", "Minute", "Label", "Repeat days", "Snooze", "Enabled"}
local EDIT_ROW = 52
local LABEL_W = 150

local function triangle(cx, cy, dir, s)
    love.graphics.polygon("fill", cx + dir * s, cy, cx - dir * s, cy - s, cx - dir * s, cy + s)
end

-- "<  07  >" : the value with arrows either side
local function stepper(text, font, x, mid, focused)
    local tw = font:getWidth(text)
    rowC(focused, "text_secondary", focused and 0.8 or 0.7)
    triangle(x + 5, mid, -1, 6)
    love.graphics.setFont(font); rowC(focused, "text_primary")
    love.graphics.print(text, x + 22, mid - font:getHeight() / 2)
    rowC(focused, "text_secondary", focused and 0.8 or 0.7)
    triangle(x + 22 + tw + 17, mid, 1, 6)
    return x + 22 + tw + 34
end

local function drawEditRow(fi, x, y, w, rowH, focused)
    local mid = y + rowH / 2
    love.graphics.setFont(FN.sm); rowC(focused, "text_secondary", focused and 0.85 or 1)
    love.graphics.print(EDIT_FIELDS[fi]:upper(), x, mid - FN.sm:getHeight() / 2)
    local vx = x + LABEL_W
    local function hint(text)
        if not focused then return end
        love.graphics.setFont(FN.xs); setC("on_accent", 0.8)
        love.graphics.print(text, x + w - FN.xs:getWidth(text), mid - FN.xs:getHeight() / 2)
    end

    if fi == 1 then
        stepper(string.format("%02d", editAlarm.hour), FN.xl, vx, mid, focused)
        hint("L1 / R1   +/- 1 h")
    elseif fi == 2 then
        stepper(string.format("%02d", editAlarm.minute), FN.xl, vx, mid, focused)
        hint("L1 / R1   +/- 10 min")
    elseif fi == 3 then
        love.graphics.setFont(FN.md); rowC(focused, "text_primary")
        MARQ(editAlarm.label, vx, mid - FN.md:getHeight() / 2, w - LABEL_W - 90, { font = FN.md, active = focused })
        hint("A   change")
    elseif fi == 4 then
        local cw, ch, gap = 36, 26, 4
        love.graphics.setFont(FN.xs)
        for di, dlbl in ipairs(Config.DAY_LABELS) do
            local cx = vx + (di - 1) * (cw + gap)
            local on = bit.band(editAlarm.repeat_days, bit.lshift(1, di - 1)) ~= 0
            local cy = mid - ch / 2 - 2
            local tw = FN.xs:getWidth(dlbl)
            if on then
                if focused then setC("on_accent") else setC("accent") end
                rect("fill", cx, cy, cw, ch, 4)
                if focused then setC("accent") else setC("on_accent") end
            else
                rowC(focused, "text_disabled", focused and 0.7 or 1)
                love.graphics.setLineWidth(1.5); rect("line", cx, cy, cw, ch, 4)
            end
            love.graphics.print(dlbl, cx + (cw - tw) / 2, cy + (ch - FN.xs:getHeight()) / 2)
            if focused and di == editRepDay then          -- the cursor
                setC("on_accent"); rect("fill", cx, cy + ch + 3, cw, 3, 1)
            end
        end
        local once = editAlarm.repeat_days == 0
        local ox = vx + 7 * (cw + gap) + 8
        love.graphics.setFont(FN.sm)
        if once then rowC(focused, "text_primary") else rowC(focused, "text_disabled", focused and 0.7 or 1) end
        love.graphics.print(once and "Once" or "", ox, mid - FN.sm:getHeight() / 2 - 2)
    elseif fi == 5 then
        stepper(Config.SNOOZE_OPTIONS[editAlarm.snooze_idx] .. " min", FN.md, vx, mid, focused)
    elseif fi == 6 then
        love.graphics.setFont(FN.lg)
        local on = editAlarm.enabled
        if focused then setC("on_accent") else setC(on and "ok" or "muted") end
        love.graphics.print(on and "ON" or "OFF", vx, mid - FN.lg:getHeight() / 2)
        hint("< >   toggle")
    end
end

local function editOpts() return { id = "edit", rowH = EDIT_ROW } end

local function editFooter()
    local items
    if editField == 4 then
        items = { { icon = "a", label = "Toggle day" }, { icon = "x", label = "Clear all" },
                  { icon = "y", label = "Preset time" }, { icon = "start", label = "Save" } }
    elseif editField == 3 then
        items = { { icon = "a", label = "Change label" }, { icon = "y", label = "Preset time" },
                  { icon = "start", label = "Save" } }
    else
        items = { { icon = "a", label = "Save" }, { icon = "y", label = "Preset time" } }
    end
    items[#items + 1] = { icon = "b", label = "Cancel", side = "right" }
    foot(items)
end

local function openPresetPicker()
    local target = editAlarm.hour * 60 + editAlarm.minute
    local best, bestDist = 1, math.huge
    for pi, p in ipairs(presetList) do
        local d = math.abs(p.hour * 60 + p.minute - target)
        if d < bestDist then bestDist = d; best = pi end
    end
    presetIdx = best
    SC.go("preset_time")
end

local function wrapStep(v, d, lo, hi) v = v + d; if v < lo then return hi elseif v > hi then return lo end; return v end

local function editInput(key)
    if key == "up" then editField = wrapStep(editField, -1, 1, #EDIT_FIELDS)
    elseif key == "down" then editField = wrapStep(editField, 1, 1, #EDIT_FIELDS)
    elseif key == "right" or key == "left" then
        local d = key == "right" and 1 or -1
        if editField == 1 then editAlarm.hour = (editAlarm.hour + d) % 24
        elseif editField == 2 then editAlarm.minute = (editAlarm.minute + d) % 60
        elseif editField == 4 then editRepDay = wrapStep(editRepDay, d, 1, 7)
        elseif editField == 5 then editAlarm.snooze_idx = wrapStep(editAlarm.snooze_idx, d, 1, #Config.SNOOZE_OPTIONS)
        elseif editField == 6 then editAlarm.enabled = not editAlarm.enabled
        end
    elseif key == "l1" or key == "r1" then
        local d = key == "r1" and 1 or -1
        if editField == 1 then editAlarm.hour = (editAlarm.hour + d) % 24
        elseif editField == 2 then editAlarm.minute = (editAlarm.minute + d * 10) % 60
        end
    elseif key == "a" then
        if editField == 3 then
            labelSelIdx = 1
            for i, lbl in ipairs(Config.PRESET_LABELS) do if lbl == editAlarm.label then labelSelIdx = i end end
            SC.go("label_pick")
        elseif editField == 4 then
            editAlarm.repeat_days = bit.bxor(editAlarm.repeat_days, bit.lshift(1, editRepDay - 1))
        else
            saveEditAlarm()
        end
    elseif key == "start" then
        saveEditAlarm()                       -- save from anywhere in the edit screen
    elseif key == "x" and editField == 4 then
        editAlarm.repeat_days = 0
    elseif key == "y" then
        openPresetPicker()
    elseif key == "b" then
        SC.go("main")
    end
end

-- ============================================================
-- PICKERS
-- ============================================================
local function presetOpts() return { id = "preset", rowH = 40 } end
local function labelOpts()  return { id = "labels", rowH = 40 } end

-- ============================================================
-- SCENES
-- ============================================================
local SCENES = {}

SCENES.main = {
    enter = function() LIST.reset("alarms"); clampSel() end,
    draw = function()
        head("ClockMu", #alarms .. "/" .. Config.MAX_ALARMS .. " alarms")
        drawHero()
        local o = alarmOpts()
        o.draw = drawAlarmRow
        LIST(alarms, selIdx, o)
        foot(MAIN_HINTS)
    end,
    input = function(key)
        local n = LIST.nav(selIdx, key, #alarms, LIST.pageSize(alarmOpts()))
        if n then selIdx = n
        elseif key == "a" and #alarms > 0 then openEdit(alarms[selIdx], false, selIdx)
        elseif key == "x" and #alarms > 0 then
            alarms[selIdx].enabled = not alarms[selIdx].enabled
            Alarm.SaveAll(alarms)
        elseif key == "y" then
            if #alarms < Config.MAX_ALARMS then
                local now = os.date("*t")
                openEdit(Alarm.New(now.hour, now.min, "Alarm " .. (#alarms + 1), 0, true), true)
            else
                UI.dialog.open{
                    title = "Alarm limit", body = "ClockMu keeps " .. Config.MAX_ALARMS
                        .. " alarms. Delete one to add another.",
                    confirm = "OK", cancel = "Close", tone = "accent",
                }
            end
        elseif key == "start" and #alarms > 0 then
            local a = alarms[selIdx]
            UI.dialog.open{
                title = "Delete alarm?", body = Alarm.TimeString(a) .. "   " .. a.label,
                confirm = "Delete", cancel = "Keep", tone = "danger",
                onConfirm = function()
                    table.remove(alarms, selIdx)
                    clampSel()
                    Alarm.SaveAll(alarms)
                end,
            }
        elseif key == "select" then SC.go("theme")
        elseif key == "b" then quitDialog() end
    end,
}

SCENES.edit = {
    enter = function() LIST.reset("edit") end,
    draw = function()
        head(editAlarm._isNew and "New alarm" or "Edit alarm",
             string.format("%02d:%02d", editAlarm.hour, editAlarm.minute))
        local o = editOpts()
        o.draw = function(fi, x, y, w, rowH, focused) drawEditRow(fi, x, y, w, rowH, focused) end
        local rows = {}
        for i = 1, #EDIT_FIELDS do rows[i] = i end
        LIST(rows, editField, o)
        editFooter()
    end,
    input = editInput,
}

SCENES.preset_time = {
    enter = function() LIST.reset("preset") end,
    draw = function()
        head("Pick a time", presetIdx .. "/" .. #presetList)
        local o = presetOpts()
        o.draw = function(p, x, y, w, rowH, focused)
            love.graphics.setFont(FN.xl); rowC(focused, "text_primary")
            love.graphics.print(string.format("%02d:%02d", p.hour, p.minute), x, y + (rowH - FN.xl:getHeight()) / 2)
        end
        LIST(presetList, presetIdx, o)
        foot({ { icon = "a", label = "Select" }, { icon = "l1", label = "Page up" },
               { icon = "r1", label = "Page down" }, { icon = "b", label = "Cancel", side = "right" } })
    end,
    input = function(key)
        local n = LIST.nav(presetIdx, key, #presetList, LIST.pageSize(presetOpts()))
        if n then presetIdx = n
        elseif key == "a" then
            local p = presetList[presetIdx]
            editAlarm.hour, editAlarm.minute = p.hour, p.minute
            SC.go("edit")
        elseif key == "b" then SC.go("edit") end
    end,
}

SCENES.label_pick = {
    enter = function() LIST.reset("labels") end,
    draw = function()
        head("Choose label")
        local o = labelOpts()
        o.draw = function(lbl, x, y, w, rowH, focused)
            love.graphics.setFont(FN.md)
            if lbl == "Custom..." then rowC(focused, "accent") else rowC(focused, "text_primary") end
            love.graphics.print(lbl, x, y + (rowH - FN.md:getHeight()) / 2)
        end
        LIST(Config.PRESET_LABELS, labelSelIdx, o)
        foot({ { icon = "a", label = "Select" }, { icon = "l1", label = "Page up" },
               { icon = "r1", label = "Page down" }, { icon = "b", label = "Cancel", side = "right" } })
    end,
    input = function(key)
        local n = LIST.nav(labelSelIdx, key, #Config.PRESET_LABELS, LIST.pageSize(labelOpts()))
        if n then labelSelIdx = n
        elseif key == "a" then
            local chosen = Config.PRESET_LABELS[labelSelIdx]
            if chosen == "Custom..." then
                -- the shared keyboard (letters + a symbols page); empty text keeps the old label
                UI.osk.open{
                    title = "Alarm label", text = editAlarm.label, max = 20,
                    onDone = function(text)
                        if text ~= "" then editAlarm.label = text end
                        SC.go("edit")
                    end,
                    onCancel = function() SC.go("edit") end,
                }
            else
                editAlarm.label = chosen
                SC.go("edit")
            end
        elseif key == "b" then SC.go("edit") end
    end,
}

SCENES.theme = {
    enter = function() themePicker = UI.themepicker.new() end,
    draw = function() themePicker:draw() end,
    input = function(key)
        if themePicker:input(key) then SC.go("main") end
    end,
}

-- the alarm: a flashing header, the time big, A snoozes, B dismisses
SCENES.ringing = {
    enter = function() startRinging() end,
    update = function(dt)
        ringAge = ringAge + dt
        ringTimer = ringTimer + dt
        if ringTimer >= 0.5 then ringTimer = 0; ringFlash = not ringFlash end
    end,
    draw = function()
        local a = alarms[ringingIdx]
        if not a then return end
        local role = (ringFlash or not fskit.motion.enabled) and "warn" or "accent"
        -- header
        setC(role); rect("fill", 0, 0, L.SW, L.HDR_H)
        local on = UI.util.readable(role)
        love.graphics.setFont(FN.xl); setC(on)
        love.graphics.print("ALARM", math.max(L.PAD, fskit.screen.SAFE), (L.HDR_H - FN.xl:getHeight()) / 2)

        local x, y, w, h = content()
        CARD.draw(x, y, w, h, { role = "warn" })
        local cx = x + w / 2 + L.BAR / 2
        local ts = Alarm.TimeString(a)
        local tf = fRing
        local block = tf:getHeight() + FN.dlg:getHeight() + FN.sm:getHeight() + 18
        local ty = y + (h - block) / 2
        love.graphics.setFont(tf); setC("accent")
        love.graphics.print(ts, cx - tf:getWidth(ts) / 2, ty)
        ty = ty + tf:getHeight() + 8
        love.graphics.setFont(FN.dlg); setC("text_primary")
        MARQ(a.label, x + 40, ty, w - 80, { font = FN.dlg, align = "center" })
        ty = ty + FN.dlg:getHeight() + 10
        love.graphics.setFont(FN.sm); setC("text_secondary")
        local sub = Alarm.RepeatString(a)
        love.graphics.print(sub, cx - FN.sm:getWidth(sub) / 2, ty)

        foot({ { icon = "a", label = "Snooze (" .. Config.SNOOZE_OPTIONS[a.snooze_idx] .. " min)" },
               { icon = "b", label = "Dismiss", side = "right" } })
    end,
    input = function(key)
        local a = alarms[ringingIdx]
        if not a or ringAge < RING_GUARD then return end
        if key == "b" then
            stopRinging()
            a.state = "idle"
            if a.repeat_days == 0 then a.enabled = false end
            Alarm.SaveAll(alarms)
            SC.go("main", nil, true)
        elseif key == "a" then
            stopRinging()
            a.state = "snoozed"
            a.snooze_until = os.time() + Config.SNOOZE_OPTIONS[a.snooze_idx] * 60
            Alarm.SaveAll(alarms)
            SC.go("main", nil, true)
        end
    end,
}

-- ============================================================
-- LOVE CALLBACKS
-- ============================================================
function love.load()
    fskit.load()

    fClock = FN.clock
    -- the big readout on the alarm screen, sized to the screen
    local size = (L.profile == "square") and 150 or 104
    local ok, big = pcall(love.graphics.newFont, "fskit/assets/font/Bold.ttf", size)
    fRing = ok and big or FN.clock
    if ok then big:setFilter("linear", "linear") end

    fskit.theme.bind{ load = Config.LoadTheme, save = Config.SaveTheme }

    buildPresets()
    love.filesystem.createDirectory("data")
    alarms = Alarm.LoadAll()
    if #alarms > 0 then Alarm.SaveAll(alarms) end   -- persist source->save on first run
    tryLoadSound()

    SC.register(SCENES)
    fskit.hookInput()
    SC.start("main")
end

function love.update(dt)
    SC.update(dt)          -- motion clock + overlay + scene (+ the ringing flash)

    if SC.now() == "ringing" then return end

    local now       = os.date("*t")
    local minuteKey = now.hour * 60 + now.min
    -- a normal alarm is due in second 0 of its minute (once); a snoozed one the
    -- moment its snooze runs out (checked every frame)
    local due = minuteKey ~= lastFiredMin and now.sec == 0
    for i, a in ipairs(alarms) do
        if (due or a.state == "snoozed") and Alarm.ShouldFire(a) then
            lastFiredMin = minuteKey
            ringingIdx   = i
            a.state      = "ringing"
            Alarm.SaveAll(alarms)
            -- an alarm outranks everything: close any dialog / keyboard that is open
            SC.clearOverlay()
            SC.go("ringing", nil, true)
            break
        end
    end
end

function love.draw()
    fskit.screen.begin()
    setC("bg_main"); rect("fill", 0, 0, L.SW, L.SH)
    SC.draw()
    fskit.screen.finish()
end

function love.resize(w, h) fskit.screen.resize(w, h) end

-- ============================================================
-- QUIT  (top-level: fires however the app is closed)
-- ============================================================
function love.quit()
    Alarm.SaveAll(alarms)
    Config.SaveTheme(fskit.theme.id())   -- theme is also saved on change; belt and braces (the ID, not the index)
    return false
end

-- Headless UI smoke for ClockMu: stub love, run love.load, then drive EVERY scene
-- (list, edit, preset picker, label picker, keyboard, theme picker, ringing, the
-- dialogs) through update/draw/input against a throwaway data dir and a fake
-- clock. Real rendering at three sizes and theme persistence run in LÖVE:
-- test/lovetest.sh.   sh test/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path
if not bit then bit = require("bit") end
local DATA = assert(os.getenv("DATA"), "set DATA (use test/run.sh)")
local noop = function() end
local FONT = {
    getHeight = function() return 12 end, getWidth = function(_, s) return #(s or "") * 6 end,
    getLineHeight = function() return 1 end, setFilter = noop, setFallbacks = noop,
    getWrap = function(_, s, w)
        local lines, per = {}, math.max(1, math.floor(w / 6))
        for para in ((s or "") .. "\n"):gmatch("(.-)\n") do
            if para == "" then lines[#lines + 1] = "" end
            for i = 1, #para, per do lines[#lines + 1] = para:sub(i, i + per - 1) end
        end
        return w, lines
    end,
}
local G = setmetatable({}, { __index = function() return noop end })
G.newFont = function() return FONT end; G.newCanvas = function() return { setFilter = noop } end
G.newShader = function() return { send = noop } end
G.getFont = function() return FONT end
G.getDimensions = function() return 640, 480 end
G.getWidth = function() return 640 end; G.getHeight = function() return 480 end
local seen = {}
G.print  = function(t) seen[#seen + 1] = tostring(t) end
G.printf = function(t) seen[#seen + 1] = tostring(t) end
local function onScreen(pat) for _, t in ipairs(seen) do if t:find(pat, 1, true) then return true end end return false end

local q = false
love = { graphics = G, timer = { getTime = function() return 0 end }, event = { quit = function() q = true end },
  audio = setmetatable({ newSource = function() return setmetatable({}, { __index = function() return noop end }) end },
                       { __index = function() return noop end }),
  keyboard = { isDown = function() return false end },
  filesystem = setmetatable({ getInfo = function() return nil end, read = function() return nil end,
    write = function() return true end, createDirectory = noop }, { __index = function() return noop end }) }
package.loaded.love = love; package.preload["love"] = function() return love end

-- a fake clock: Mon 5 Oct 2026 07:00:10 (not second 0, so nothing rings by accident)
local real_date, real_time = os.date, os.time
local NOW = real_time{ year = 2026, month = 10, day = 5, hour = 7, min = 0, sec = 10 }
os.time = function(t) if t then return real_time(t) end return NOW end
os.date = function(f, t) return real_date(f, t or NOW) end

local fails, checks = 0, 0
local function ck(c, m) checks = checks + 1; if not c then fails = fails + 1; print("  FAIL: " .. m) end end
dofile("./main.lua")
ck(pcall(love.load), "love.load")
local fskit = require("fskit")
local function frame(n)
    for _ = 1, (n or 1) do
        local a, e1 = pcall(love.update, 0.016); ck(a, "update@" .. tostring(fskit.scene.now()) .. ": " .. tostring(e1))
        seen = {}
        local b, e2 = pcall(love.draw);          ck(b, "draw@" .. tostring(fskit.scene.now()) .. ": " .. tostring(e2))
    end
end
local function press(x) fskit.scene.input(x); frame(1) end
local function settle() frame(50) end
local function now(want, msg) ck(fskit.scene.now() == want, msg .. " (got " .. tostring(fskit.scene.now()) .. ")") end
local function file(name) local f = io.open(DATA .. "/" .. name, "rb"); if not f then return "" end local d = f:read("*a"); f:close(); return d end
local function alarmLines() local t = {}; for l in file("alarms.txt"):gmatch("[^\n]+") do t[#t + 1] = l end return t end

-- ---- main, empty
now("main", "starts on the alarm list")
frame(3)
ck(onScreen("No alarms"), "an empty list says so")
ck(onScreen("07:00"), "the clock card shows the time")
press("x"); press("start"); press("a"); frame(2); now("main", "toggle / delete / edit do nothing on an empty list")

-- ---- add an alarm (Y): edit it field by field
press("y"); settle(); now("edit", "Y -> new alarm")
ck(onScreen("NEW ALARM"), "the header says New alarm")
press("r1"); press("r1"); press("l1")                    -- hour 07 -> 08 -> 09 -> 08
press("down"); press("r1"); press("r1"); press("l1")     -- minute 00 -> 10 -> 20 -> 10
press("right")                                            -- 11
press("down")                                             -- label
press("a"); settle(); now("label_pick", "A on Label -> label picker")
press("down"); press("a"); settle(); now("edit", "pick a preset label -> edit")
ck(onScreen("Morning") or onScreen("Wake Up"), "the picked label shows")
press("down")                                             -- repeat days
press("a"); press("right"); press("a"); press("right"); press("a")   -- Mon, Tue, Wed on
press("left"); press("a")                                 -- Tue off
press("down"); press("right")                             -- snooze 5 -> 10
press("down"); press("left"); press("left")               -- enabled off, on
press("start"); settle(); now("main", "START saves -> list")
local l = alarmLines()
ck(#l == 1, "one alarm saved (" .. #l .. ")")
local h, m, lbl, rep, en, sn = (l[1] or ""):match("^(%d+)|(%d+)|([^|]*)|(%d+)|([01])|(%d+)$")
ck(h == "8" and m == "11", "time 08:11 saved (" .. tostring(h) .. ":" .. tostring(m) .. ")")
ck(lbl ~= "" and lbl ~= "Alarm 1", "label saved (" .. tostring(lbl) .. ")")
ck(rep == "5", "repeat Mon+Wed = 5 (" .. tostring(rep) .. ")")
ck(en == "1" and sn == "2", "enabled, snooze 10 min (" .. tostring(en) .. "," .. tostring(sn) .. ")")
ck(onScreen("08:11"), "the list shows the new alarm")

-- ---- preset time picker + paging
press("a"); settle(); now("edit", "A -> edit the alarm")
ck(onScreen("EDIT ALARM"), "the header says Edit alarm")
press("y"); settle(); now("preset_time", "Y -> preset time picker")
press("r2"); press("a"); settle(); now("edit", "R2 jumps to the end, A picks it")
ck(onScreen("23:45"), "23:45 picked")
press("y"); settle(); press("l2"); press("a"); settle()
ck(onScreen("00:00"), "L2 jumps to the start (00:00)")
press("y"); settle(); press("r1"); press("l1"); press("b"); settle(); now("edit", "B cancels the picker")

-- ---- keyboard: Custom... label
press("down"); press("down"); press("a"); settle(); now("label_pick", "label picker again")
press("r2"); press("a"); frame(3)
ck(fskit.scene.overlay() ~= nil, "Custom... opens the shared keyboard overlay")
press("a"); press("y"); press("a"); press("l1"); press("a"); press("x")   -- type, shift, type, symbols page, type, delete
press("start"); settle()
ck(fskit.scene.overlay() == nil, "START closes the keyboard")
now("edit", "keyboard done -> edit")
press("a"); settle(); press("r2"); press("a"); frame(3); press("b"); settle()
now("edit", "keyboard B (cancel) -> edit")
press("start"); settle(); now("main", "save")
ck(#alarmLines() == 1 and alarmLines()[1]:match("^%d+|%d+|[^|]+|"), "still one alarm, label intact")

-- ---- add up to the limit, then the limit dialog
for i = 2, 5 do press("y"); settle(); press("start"); settle() end
ck(#alarmLines() == 5, "five alarms (" .. #alarmLines() .. ")")
press("y"); frame(3)
ck(fskit.scene.overlay() ~= nil and fskit.scene.now() == "main", "a sixth alarm opens the limit dialog, not the editor")
press("a"); frame(3); ck(fskit.scene.overlay() == nil, "OK closes it")
press("down"); press("down"); press("r1"); press("l1"); press("r2"); press("l2"); frame(3); now("main", "paging keys stay on the list")

-- ---- toggle, delete
press("x"); settle()
press("start"); frame(3)
ck(fskit.scene.overlay() ~= nil, "START asks before deleting")
press("b"); frame(3); ck(#alarmLines() == 5, "Keep: nothing deleted")
press("start"); frame(3); press("a"); frame(3)
ck(#alarmLines() == 4, "Delete removes one (" .. #alarmLines() .. ")")

-- ---- theme: picker keeps (A) or restores (B); the id is saved
press("select"); settle(); now("theme", "SELECT -> theme picker")
press("down"); press("down"); press("y"); press("a"); settle(); now("main", "theme keep -> list")
ck(fskit.theme.id() == "ocean-light", "the picker applied Ocean, then Light (" .. fskit.theme.id() .. ")")
ck(file("settings.txt") == "ocean-light", "the theme id is saved (" .. file("settings.txt") .. ")")
press("select"); settle(); press("down"); press("b"); settle(); now("main", "theme cancel -> list")
ck(fskit.theme.id() == "ocean-light", "cancel restores the theme from when it opened")

-- ---- hold a direction to keep moving: Right held on the hour steps it again and again
do
    press("y"); settle(); now("edit", "Y -> a new alarm for the repeat test")
    ck(onScreen("07:00"), "a new alarm starts at the fake time 07:00")
    fskit.input.press("right"); frame(150)                  -- ~2.4 s held: 1 + ~26 steps
    fskit.input.release("right"); frame(2)
    local held = nil
    for _, t in ipairs(seen) do if t:match("^%d%d:00$") then held = t end end
    ck(held ~= nil and held ~= "07:00", "holding Right moved the hour on by itself (" .. tostring(held) .. ")")
    local before = held
    frame(60)
    local after = nil
    for _, t in ipairs(seen) do if t:match("^%d%d:00$") then after = t end end
    ck(after == before, "...and it stops when the button is released (" .. tostring(after) .. ")")
    press("b"); settle(); now("main", "B cancels the new alarm")
end

-- ---- ringing: an alarm outranks a dialog, A/B ignored for a moment, snooze comes back
press("b"); frame(3)
ck(fskit.scene.overlay() ~= nil, "B on the list opens Quit?")
-- the alarm list: find one and ring it. Set the fake clock to its minute, second 0.
local first = alarmLines()[1]
local fh, fm = first:match("^(%d+)|(%d+)|")
NOW = real_time{ year = 2026, month = 10, day = 7, hour = tonumber(fh), min = tonumber(fm), sec = 0 }   -- a Wednesday
local before = fskit.scene.now()
frame(2)
now("ringing", "the alarm rings even with the Quit? dialog open")
ck(fskit.scene.overlay() == nil, "and the dialog is gone")
ck(onScreen("ALARM") or onScreen("Snooze"), "the ringing screen shows")
press("a"); press("b"); now("ringing", "A / B in the first moment do nothing")
frame(40)
press("a"); settle(); now("main", "A (after the guard) snoozes -> list")
NOW = NOW + 5 * 60 + 7                                    -- 5 min 7 s later: not second 0
frame(3)
now("ringing", "the snoozed alarm rings again when its time is up")
frame(40); press("b"); settle(); now("main", "B dismisses")
frame(3); now("main", "and it does not ring again")

-- ---- Quit
press("b"); frame(3)
ck(fskit.scene.overlay() ~= nil and not q, "B opens Quit?")
fskit.scene.input("b"); frame(3)
ck(fskit.scene.overlay() == nil and not q, "Stay closes it")
fskit.scene.input("b"); frame(3); fskit.scene.input("a"); frame(3)
ck(q, "Quit (A) quits")
ck(pcall(love.quit), "love.quit (what LÖVE calls on the way out)")
ck(file("settings.txt") == "ocean-light", "quitting keeps the theme id (not an index)")

print(("\n%d checks, %s"):format(checks, fails == 0 and "CM SMOKE OK" or (fails .. " FAILURES")))
os.exit(fails == 0 and 0 or 1)

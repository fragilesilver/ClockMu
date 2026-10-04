-- Harness: runs the REAL ClockMu (main.lua renamed app_main.lua) in LÖVE against a
-- throwaway data dir (CLOCKMU_DATA, seeded by test/lovetest.sh) and a fake clock,
-- drives every screen and writes PNGs, or checks theme persistence.
--   HARNESS = shots | empty | persist1 | persist2 | legacy
function love.errorhandler(msg)
    io.stderr:write(debug.traceback("harness: " .. tostring(msg), 2) .. "\n")
    os.exit(1)
end

local MODE = os.getenv("HARNESS") or "shots"
local OUT  = os.getenv("SHOT_OUT") or "/tmp/clockmu-shots"

-- fake clock: Mon 5 Oct 2026 07:29:10 (the clock card shows 07:29)
local real_date, real_time = os.date, os.time
local NOW = real_time{ year = 2026, month = 10, day = 5, hour = 7, min = 29, sec = 10 }
os.time = function(t) if t then return real_time(t) end return NOW end
os.date = function(f, t) return real_date(f, t or NOW) end

require("app_main")
local fskit = require("fskit")
local app_load = love.load

-- draw every frame, as on the device
local function frames(n, dt) for _ = 1, n do love.update(dt or 1 / 30); love.draw() end end
local function key(k) fskit.scene.input(k); frames(24) end
local function shot(name)
    love.draw()
    local img = fskit.screen.canvas():newImageData()
    local f = assert(io.open(("%s/%s_%dx%d.png"):format(OUT, name, fskit.screen.W, fskit.screen.H), "wb"))
    f:write(img:encode("png"):getString()); f:close()
end

function love.load()
    app_load()
    if MODE == "persist2" or MODE == "legacy" then
        print("THEME " .. fskit.theme.id())
        love.event.quit(0); return
    end
    local want = os.getenv("SHOT_THEME")
    if want then fskit.theme.setId(want) end

    if MODE == "persist1" then
        key("select"); key("down"); key("down"); key("y"); key("a")      -- Ocean, then Light, keep
        print("THEME " .. fskit.theme.id() .. " scene " .. tostring(fskit.scene.now()))
        love.event.quit(0); return
    end

    os.execute("mkdir -p '" .. OUT .. "'")
    if MODE == "empty" then
        frames(10); shot("0_empty")
        key("y"); shot("0b_new_alarm"); key("b")
        print("HARNESS DONE"); love.event.quit(0); return
    end

    frames(10); shot("1_main")
    key("down"); key("down"); frames(6); shot("1b_main_selected")
    key("r1"); shot("1c_main_paged"); key("l1"); key("l1"); key("l1")
    -- edit: each kind of field
    key("a"); shot("2_edit_hour")
    key("down"); key("down"); shot("2b_edit_label")
    key("down"); key("right"); key("a"); shot("2c_edit_repeat")
    key("down"); shot("2d_edit_snooze")
    key("down"); shot("2e_edit_enabled")
    key("up"); key("up"); key("up"); key("a"); shot("3_label_pick")
    key("r2"); shot("3b_label_pick_end")
    key("a"); shot("4_keyboard")
    key("y"); key("a"); key("l1"); shot("4b_keyboard_symbols")
    key("b"); key("up"); key("up"); key("up"); key("up"); key("up"); key("y"); shot("5_preset_time")
    key("r1"); shot("5b_preset_paged"); key("b"); key("b")
    key("x"); shot("6_toggled")
    key("start"); shot("7_delete_dialog"); key("b")
    key("select"); shot("8_theme"); key("b")
    key("b"); frames(12); shot("9_quit_dialog"); key("b")
    -- ring alarm 1 (07:30), snooze it, ring again, dismiss
    NOW = real_time{ year = 2026, month = 10, day = 5, hour = 7, min = 30, sec = 0 }
    frames(14); shot("10_ringing_a")
    frames(12); shot("10_ringing_b")
    frames(20); fskit.scene.input("a"); frames(10); shot("11_snoozed")
    for _ = 1, 3 do key("y") end                                         -- (fills the list to the limit)
    key("y"); shot("12_limit_dialog")
    print("HARNESS DONE")
    love.event.quit(0)
end

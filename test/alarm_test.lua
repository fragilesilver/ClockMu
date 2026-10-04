-- Alarm logic (alarm.lua), against a fake clock. Headless: luajit test/alarm_test.lua
package.path = "./?.lua;" .. package.path
if not bit then bit = require("bit") end
local real_date, real_time = os.date, os.time
local NOW
os.time = function(t) if t then return real_time(t) end return NOW end
os.date = function(f, t) return real_date(f, t or NOW) end
local Alarm = require("alarm")

local fails, checks = 0, 0
local function ck(c, m) checks = checks + 1; if not c then fails = fails + 1; print("  FAIL: " .. m) end end
-- Mon 5 Oct 2026
local function at(h, m, s, day) NOW = real_time{ year = 2026, month = 10, day = day or 5, hour = h, min = m, sec = s or 0 } end

-- one-shot: only at hh:mm:00
local a = Alarm.New(7, 30, "Wake", 0, true)
at(7, 29, 59); ck(not Alarm.ShouldFire(a), "not a second early")
at(7, 30, 0);  ck(Alarm.ShouldFire(a), "fires at 07:30:00")
a = Alarm.New(7, 30, "Wake", 0, true)
at(7, 30, 1);  ck(not Alarm.ShouldFire(a), "not at 07:30:01 (the tick looks at second 0)")
a = Alarm.New(7, 30, "Wake", 0, false)
at(7, 30, 0);  ck(not Alarm.ShouldFire(a), "a disabled alarm never fires")
a = Alarm.New(7, 30, "Wake", 0, true); a.state = "ringing"
at(7, 30, 0);  ck(not Alarm.ShouldFire(a), "an already ringing alarm does not fire again")

-- repeat days: bit 1 = Mon .. bit 7 = Sun
a = Alarm.New(7, 30, "Work", 31, true)       -- Mon-Fri
at(7, 30, 0, 5);  ck(Alarm.ShouldFire(a), "Mon-Fri alarm fires on a Monday")
a = Alarm.New(7, 30, "Work", 31, true)
at(7, 30, 0, 10); ck(not Alarm.ShouldFire(a), "Mon-Fri alarm is quiet on a Saturday (10 Oct)")
a = Alarm.New(7, 30, "Sun", 64, true)
at(7, 30, 0, 11); ck(Alarm.ShouldFire(a), "a Sunday-only alarm fires on Sunday (11 Oct)")

-- snooze: rings again when it runs out, at any time of day (1.0 never did)
a = Alarm.New(7, 30, "Wake", 0, true)
at(7, 30, 12)
a.state = "snoozed"; a.snooze_until = NOW + 5 * 60
at(7, 34, 59); ck(not Alarm.ShouldFire(a), "snoozed: quiet until the time is up")
at(7, 35, 12); ck(Alarm.ShouldFire(a), "snoozed: fires when snooze_until arrives (07:35:12, not second 0, not 07:30)")
ck(a.state == "idle" and a.snooze_until == nil, "snoozed: state reset after it fires")
a = Alarm.New(7, 30, "Wake", 0, true); a.state = "snoozed"; a.snooze_until = NOW - 1
at(9, 0, 33);  ck(Alarm.ShouldFire(a), "snoozed: still fires if a frame was missed")
a = Alarm.New(7, 30, "Wake", 0, false); a.state = "snoozed"; a.snooze_until = NOW - 1
at(9, 0, 33);  ck(not Alarm.ShouldFire(a), "snoozed but disabled: stays quiet")

-- storage round trip
local line = Alarm.Serialize(Alarm.New(6, 5, "Gym | early", 31, true, 2))
local b = Alarm.Deserialize(line)
ck(b and b.hour == 6 and b.minute == 5 and b.label == "Gym  early" and b.repeat_days == 31 and b.enabled and b.snooze_idx == 2,
   "serialize / deserialize round trip (pipes stripped from the label)")
ck(Alarm.RepeatString(Alarm.New(1, 1, "x", 31)) == "Weekdays" and Alarm.RepeatString(Alarm.New(1, 1, "x", 0)) == "Once"
   and Alarm.RepeatString(Alarm.New(1, 1, "x", 127)) == "Every day", "repeat strings")

print(("\n%d checks, %s"):format(checks, fails == 0 and "ALARM OK" or (fails .. " FAILURES")))
os.exit(fails == 0 and 0 or 1)

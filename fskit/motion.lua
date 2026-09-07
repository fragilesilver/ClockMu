-- fskit/motion.lua
-- Andromeda-feel motion: a global clock, easing, tweens, and the BatteryMu
-- glow/pulse/shimmer helpers promoted to shared code. Everything degrades to a
-- no-op / instant when motion.enabled is false (reduce-motion).

local theme = require("fskit.theme")

local motion = { enabled = true }

local t = 0
function motion.update(dt) t = t + (dt or 0) end
function motion.time() return t end

-- ---- easing (allocation-free) ---------------------------------------
motion.ease = {
    linear      = function(x) return x end,
    outCubic    = function(x) x = x - 1; return x * x * x + 1 end,
    outQuint    = function(x) x = x - 1; return x ^ 5 + 1 end,
    inOutCubic  = function(x)
        if x < 0.5 then return 4 * x * x * x end
        x = 2 * x - 2; return 0.5 * x * x * x + 1
    end,
}

-- normalised progress 0..1 for a timer, eased
function motion.progress(elapsed, dur, ease)
    if not motion.enabled or dur <= 0 then return 1 end
    local x = elapsed / dur
    if x < 0 then x = 0 elseif x > 1 then x = 1 end
    return (ease or motion.ease.outCubic)(x)
end

function motion.lerp(a, b, x) return a + (b - a) * x end

-- ---- breathing / glow / shimmer -----------------------------------
-- 0..1 sine; steady 1 when motion is off so callers still light up
function motion.pulse(speed, phase)
    if not motion.enabled then return 1 end
    return (math.sin(t * (speed or 2) + (phase or 0)) + 1) * 0.5
end

-- soft outer glow around a rounded rect, in colour `col` (an {r,g,b} table or
-- a theme role name), intensity 0..1
function motion.glowRect(x, y, w, h, col, intensity, r)
    if not motion.enabled or not intensity or intensity <= 0.01 then return end
    if type(col) == "string" then col = { theme.get(col) } end
    r = r or 8
    local layers = 4
    for i = layers, 1, -1 do
        local spread = i * 2
        love.graphics.setColor(col[1], col[2], col[3], intensity * 0.10)
        love.graphics.rectangle("line", x - spread, y - spread,
            w + spread * 2, h + spread * 2, r + spread, r + spread)
    end
end

-- moving highlight band inside (x,y,w,h) — progress bars, fills
function motion.shimmer(x, y, w, h, phase)
    if not motion.enabled then return end
    local p = ((t * 0.4) + (phase or 0)) % 1.0
    local bx = x + w * p
    love.graphics.setColor(1, 1, 1, 0.10)
    love.graphics.rectangle("fill", bx, y, math.max(2, w * 0.04), h)
end

return motion

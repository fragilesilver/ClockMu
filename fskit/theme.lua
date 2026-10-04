-- fskit/theme.lua
-- In-app colour theme: a fixed set of named palettes (5 colours x dark/light),
-- one active at a time, read live at draw time. Nothing here touches muOS's own
-- theme files.
--
--   theme.get(role)    -> r, g, b        (0..1)
--   theme.rgba(role,a) -> love.graphics.setColor(r,g,b,a)
--   theme.set(i)       -> switch by position (1..10), fires onChange immediately
--   theme.setId(id)    -> switch by stable id ("ocean-light")
--   theme.id() / family() / mode() / name() / isLight()
--   theme.toggleMode() -> the same colour's dark <-> light sibling
--   theme.siblingIndex(i) / theme.familyIndex(i): picker helpers
--
-- Persistence is delegated to the host app via theme.bind{ load=, save= }:
--   save(id)   gets the stable id string ("mustard-dark"), never a position, so
--              the list can change without losing anybody's choice
--   load()     returns that id, or (from an app saved before fskit 0.3) the OLD
--              1..8 index, which is migrated once (LEGACY below)

local themes = require("fskit.themes")

local theme = {}

local active    = 1
local observers = {}
local io_load, io_save

-- pre-0.3 positions -> ids (Intense Orange and Forest Green were dropped)
local LEGACY = {
    [1] = "mustard-dark", [2] = "mustard-dark", [3] = "crimson-dark", [4] = "ocean-dark",
    [5] = "mustard-dark", [6] = "funky-dark",   [7] = "andromeda-light", [8] = "andromeda-dark",
}

-- role -> role fallback when a palette omits a key
local FALLBACK = {
    ok        = "accent",
    full      = "accent_glow",
    danger    = "warn",
    separator = "accent_dim",
    muted     = "text_disabled",
    on_accent = "bg_main",
}

local byId = {}
for i, t in ipairs(themes) do byId[t.id] = i end

local function clamp(i)
    i = tonumber(i) or 1
    if i < 1 then i = 1 end
    if i > #themes then i = #themes end
    return math.floor(i)
end

function theme.count() return #themes end
function theme.index() return active end
function theme.name()  return themes[active].name end
function theme.id()    return themes[active].id end
function theme.family() return themes[active].family end
function theme.mode()  return themes[active].mode end
function theme.isLight() return themes[active].light == true end

function theme.list()
    local names = {}
    for i, t in ipairs(themes) do names[i] = t.name end
    return names
end

-- full palette table for a given index (used by the picker's swatches)
function theme.palette(i) return themes[clamp(i or active)] end

-- index of an id (nil if unknown)
function theme.indexOf(id) return byId[id] end

-- index of the same colour in the other mode (or in the given mode)
function theme.siblingIndex(i, mode)
    local p = themes[clamp(i or active)]
    local want = mode or (p.mode == "dark" and "light" or "dark")
    for j, t in ipairs(themes) do
        if t.family == p.family and t.mode == want then return j end
    end
    return clamp(i or active)
end

-- index of `family` in `mode` ("Ocean", "light")
function theme.familyIndex(family, mode)
    for j, t in ipairs(themes) do
        if t.family == family and t.mode == mode then return j end
    end
end

function theme.get(role)
    local t = themes[active]
    local c = t[role]
    if not c then
        local fb = FALLBACK[role]
        c = fb and t[fb]
    end
    if not c then return 1, 0, 1 end   -- magenta = missing key, obvious in dev
    return c[1], c[2], c[3]
end

function theme.rgba(role, a)
    local r, g, b = theme.get(role)
    love.graphics.setColor(r, g, b, a or 1)
end

function theme.onChange(fn)
    observers[#observers + 1] = fn
end

local function fire()
    for _, fn in ipairs(observers) do fn(active) end
end

function theme.set(i)
    local n = clamp(i)
    if n == active then return end
    active = n
    if io_save then io_save(themes[active].id) end
    fire()
end

function theme.setId(id)
    local i = byId[id]
    if i then theme.set(i) end
    return i ~= nil
end

function theme.toggleMode() theme.set(theme.siblingIndex(active)) end

-- what load() returned -> an index, or nil. Strings are ids; numbers are the
-- pre-0.3 position (a numeric string, as some hosts stored it, counts too).
local function resolve(v)
    if v == nil or v == "" then return nil end
    if byId[v] then return byId[v] end
    local n = tonumber(v)
    if n and LEGACY[math.floor(n)] then return byId[LEGACY[math.floor(n)]] end
    return nil
end
theme._resolve = resolve        -- for tests

-- host wires persistence: load() -> id (or legacy index) or nil ; save(id)
function theme.bind(opt)
    io_load = opt and opt.load
    io_save = opt and opt.save
    if io_load then
        local i = resolve(io_load())
        if i then active = i end
    end
end

return theme

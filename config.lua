-- ClockMu -- app configuration
-- Colour themes live in fskit/themes.lua and are driven through fskit.theme.

local Config = {}

-- ============================================================
-- PERSISTENT STORE
-- ------------------------------------------------------------
-- On muOS the launcher exports CLOCKMU_DATA (an absolute, writable dir inside
-- the app). We write there with plain io so nothing depends on LÖVE's save-dir
-- resolution, fused-mode source shadowing, or bind-mount quirks. On desktop
-- (no env var) we fall back to love.filesystem under "data/".
-- ============================================================
local STORE_DIR = os.getenv("CLOCKMU_DATA")

local function store_path(name)
    return STORE_DIR and (STORE_DIR .. "/" .. name) or nil
end

Config.store = {}

function Config.store.read(name)
    local p = store_path(name)
    if p then
        local f = io.open(p, "rb")
        if f then
            local d = f:read("*a")
            f:close()
            if d and #d > 0 then return d end
        end
        -- one-time fallback: pick up anything a previous build wrote via LÖVE
        if love and love.filesystem and love.filesystem.getInfo("data/" .. name) then
            return love.filesystem.read("data/" .. name)
        end
        return nil
    end
    if love and love.filesystem and love.filesystem.getInfo("data/" .. name) then
        return love.filesystem.read("data/" .. name)
    end
    return nil
end

function Config.store.write(name, data)
    local p = store_path(name)
    if p then
        local f, err = io.open(p, "wb")
        if not f then
            print("[ClockMu] store.write failed for " .. p .. ": " .. tostring(err))
            return false
        end
        f:write(data)
        f:close()
        return true
    end
    love.filesystem.createDirectory("data")
    return love.filesystem.write("data/" .. name, data)
end

-- ============================================================
-- FILE NAMES  (within the store)
-- ============================================================
Config.ALARMS_FILE   = "alarms.txt"
Config.SETTINGS_FILE = "settings.txt"
Config.SOUND_PATH    = "Assets/Sound/alarm.ogg"

-- ============================================================
-- ALARM SETTINGS
-- ============================================================
Config.MAX_ALARMS     = 5
Config.SNOOZE_OPTIONS = {5, 10, 15}
Config.DEFAULT_SNOOZE = 1
Config.DAY_LABELS     = {"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"}
Config.DAY_FULL       = {"Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"}

-- ============================================================
-- LABEL PRESETS  (last entry opens the on-screen keyboard)
-- ============================================================
Config.PRESET_LABELS = {
    "Wake Up", "Morning", "School", "Work", "Lunch",
    "Prayer", "Nap", "Evening", "Dinner", "Bedtime",
    "Medicine", "Meeting", "Gym", "Custom...",
}

-- ============================================================
-- ON-SCREEN KEYBOARD ROWS
-- ============================================================
Config.KB_ROWS = {
    {"1","2","3","4","5","6","7","8","9","0"},
    {"q","w","e","r","t","y","u","i","o","p"},
    {"a","s","d","f","g","h","j","k","l","-"},
    {"z","x","c","v","b","n","m","!","?","_"},
    {"SPACE","BACK","DONE"},
}

-- ============================================================
-- THEME PERSISTENCE  (bare index)
-- ============================================================
function Config.LoadTheme()
    local s = Config.store.read(Config.SETTINGS_FILE)
    return s and tonumber(s:match("%d+")) or nil
end

function Config.SaveTheme(index)
    Config.store.write(Config.SETTINGS_FILE, tostring(index))
end

return Config

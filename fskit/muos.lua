-- fskit/muos.lua
-- Small launch/exit contract helpers. The mux_launch.sh template exports the
-- app's writable data dir as <APPID>_DATA (all-caps); Lua reads it here with a
-- love.filesystem fallback for desktop dev.

local muos = {}

-- absolute, always-writable data dir for `appid` ("CLOCKMU" -> $CLOCKMU_DATA),
-- or nil on desktop (caller falls back to love.filesystem "data/")
function muos.dataDir(appid)
    return os.getenv(appid:upper() .. "_DATA")
end

-- read/write a small file under the data dir with plain io; falls back to
-- love.filesystem so the same call works on desktop.
function muos.read(appid, name)
    local dir = muos.dataDir(appid)
    if dir then
        local f = io.open(dir .. "/" .. name, "rb")
        if f then local d = f:read("*a"); f:close(); return d end
    end
    if love.filesystem.getInfo("data/" .. name) then
        return love.filesystem.read("data/" .. name)
    end
end

function muos.write(appid, name, data)
    local dir = muos.dataDir(appid)
    if dir then
        local f = io.open(dir .. "/" .. name, "wb")
        if f then f:write(data); f:close(); return true end
    end
    return love.filesystem.write("data/" .. name, data)
end

function muos.exit()
    love.event.quit()
end

return muos

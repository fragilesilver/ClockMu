-- fskit/screen.lua
-- The virtual canvas. Its size is the device's NATIVE size, so on the three muOS
-- panels nothing is scaled:
--
--   standard  640x480   RG35XX family (Pro, Plus, H, SP, 2024)
--   wide      720x480   RG34XX-H / SP
--   square    720x720   RGCubeXX
--
-- A window that matches none of them (HDMI, a desktop) gets the profile with the
-- closest aspect ratio and is letterbox-scaled (never stretched). The profile is
-- chosen when this file is first required (LÖVE creates the window before
-- main.lua runs), so `local SW, SH = fskit.layout.SW, fskit.layout.SH` at the top
-- of an app already sees the right size.
--
-- The app always draws in 0..W x 0..H. Input is button-only, so no coordinate
-- remapping is needed.

local screen = {}

screen.PROFILES = {
    { name = "standard", w = 640, h = 480 },
    { name = "wide",     w = 720, h = 480 },
    { name = "square",   w = 720, h = 720 },
}
screen.SAFE = 10          -- virtual px kept clear at each edge for chrome

local watchers = {}
local canvas
local scale, ox, oy = 1, 0, 0

-- the profile for a window of w x h: exact match, else the closest aspect
function screen.pick(w, h)
    local best, bd = screen.PROFILES[1], math.huge
    for _, p in ipairs(screen.PROFILES) do
        if p.w == w and p.h == h then return p end
        local d = math.abs(math.log((w / h) / (p.w / p.h)))
        if d < bd then best, bd = p, d end
    end
    return best
end

-- choose the profile for a window size and tell layout (and anyone else)
function screen.setSize(w, h)
    local p = screen.pick(w or 640, h or 480)
    screen.W, screen.H, screen.profile = p.w, p.h, p.name
    for _, fn in ipairs(watchers) do fn(screen.W, screen.H, screen.profile) end
    return p
end

function screen.onChange(fn)
    watchers[#watchers + 1] = fn
    fn(screen.W, screen.H, screen.profile)
end

screen.W, screen.H, screen.profile = 640, 480, "standard"
do
    local ok, w, h = pcall(function() return love.graphics.getDimensions() end)
    if ok and w and h then screen.setSize(w, h) end
end

function screen.load()
    canvas = love.graphics.newCanvas(screen.W, screen.H)
    canvas:setFilter("linear", "linear")
    local w, h = love.graphics.getDimensions()
    screen.resize(w, h)
end

function screen.resize(w, h)
    w = w or love.graphics.getWidth()
    h = h or love.graphics.getHeight()
    scale = math.min(w / screen.W, h / screen.H)
    ox = math.floor((w - screen.W * scale) / 2 + 0.5)
    oy = math.floor((h - screen.H * scale) / 2 + 0.5)
end

-- the virtual canvas (for tools/tests that capture a frame)
function screen.canvas() return canvas end

-- ImageData of the virtual canvas as drawn so far (tools/shot, tests). Call
-- after the frame is drawn into it and before screen.finish().
function screen.snapshot()
    love.graphics.setCanvas()
    return canvas:newImageData()
end

-- draw the frame into the virtual canvas
function screen.begin()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)
end

-- blit the virtual canvas to the real framebuffer, centred and scaled.
-- Optional `shader` composites a post-process (JarMu's CRT) during the blit.
function screen.finish(shader)
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    if shader then
        if shader.send then pcall(shader.send, shader, "resolution", { screen.W, screen.H }) end
        love.graphics.setShader(shader)
    end
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
    if shader then love.graphics.setShader() end
end

-- safe-area rectangle in virtual coords
function screen.safe()
    local s = screen.SAFE
    return s, s, screen.W - s * 2, screen.H - s * 2
end

return screen

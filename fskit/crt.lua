-- fskit/crt.lua
-- JarMu's CRT post-process (scanlines + chromatic aberration + vignette),
-- moved into the kit unchanged. JarMu is its only consumer (v2 decision 2):
-- ClockMu / BatteryMu / SwapMu never call crt.load().
--
--   fskit.crt.load()
--   fskit.screen.finish(fskit.crt.shader())

local crt = {}

local SRC = [[
extern number scanline_strength;
extern number aberration;
extern number vignette;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec2 offset = vec2(aberration / resolution.x, 0.0);
    float r = Texel(tex, tc + offset).r;
    float g = Texel(tex, tc).g;
    float b = Texel(tex, tc - offset).b;
    vec3 col = vec3(r, g, b);

    float scan = sin(tc.y * resolution.y * 3.14159) * 0.5 + 0.5;
    col *= 1.0 - (scanline_strength * (1.0 - scan));

    vec2 v = tc - 0.5;
    col *= 1.0 - (vignette * dot(v, v));

    return vec4(col, 1.0) * color;
}
]]

local shader

function crt.load(params)
    shader = love.graphics.newShader(SRC)
    crt.setParams(params or {})
end

function crt.setParams(p)
    if not shader then return end
    shader:send("scanline_strength", p.scanline_strength or 0.18)
    shader:send("aberration", p.aberration or 0.7)
    shader:send("vignette", p.vignette or 0.55)
    shader:send("resolution", p.resolution or { 640, 480 })
end

function crt.shader() return shader end

return crt

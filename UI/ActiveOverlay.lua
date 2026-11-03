-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Overlay = {}
Overlay.__index = Overlay
ns.ActiveOverlay = Overlay

local T = ns.Theme
local WHITE = "Interface\\Buttons\\WHITE8X8"
local FRAME = { 0.91, 1, 1 }
local INSET, HALO_OUT = 2, 2
local BREATH, HALO_LOW = 0.75, 0.25

Overlay.COLORS = {
    Cyan = { 0.25, 0.87, 1 },
    Gold = { 1, 0.78, 0.2 },
    Green = { 0.35, 1, 0.35 },
    White = { 1, 1, 1 },
}

function Overlay.New(parent, level)
    local root = CreateFrame("Frame", nil, parent)
    root:SetAllPoints(parent)
    root:SetFrameLevel(level)
    return setmetatable({ root = root, pools = {}, displays = {}, list = {}, timers = true, glow = true, color = "Cyan" }, Overlay)
end

local function textSize(size)
    return math.max(10, math.floor(size * 0.5))
end

-- The engine locks the aura button's regions right after initializeFrame (tainted SetTexture on them is forbidden),
-- so every look gets its own set of displays, dressed once.
function Overlay:Swap()
    local key = table.concat({ tostring(self.texture), tostring(self.size), tostring(self.timers), tostring(self.glow), self.color }, ":")
    if self.pools[key] and self.pools[key] == self.displays then return end
    for _, d in ipairs(self.displays) do d:SetEnabled(false) end
    self.pools[key] = self.pools[key] or {}
    self.displays = self.pools[key]
    self:Watch(self.list)
end

function Overlay:SetLook(texture, size)
    self.texture, self.size = texture, size
    self:Swap()
end

function Overlay:SetStyle(style)
    if not style then return end
    local timers, glow = style.timers ~= false, style.glow ~= false
    local color = Overlay.COLORS[style.color] and style.color or "Cyan"
    if timers == self.timers and glow == self.glow and color == self.color then return end
    self.timers, self.glow, self.color = timers, glow, color
    self:Swap()
end

-- Everything here lives on the engine's aura button, which exists only while the aura is on: no Lua reads of secret state.
function Overlay:Dress(b, look)
    b:SetSize(look.size, look.size)
    pcall(b.SetMouseClickEnabled, b, false)
    pcall(b.SetMouseMotionEnabled, b, false)
    local halo
    if look.glow then
        local c = Overlay.COLORS[look.color]
        halo = b:CreateTexture(nil, "BACKGROUND", nil, -1)
        halo:SetTexture(WHITE)
        halo:SetVertexColor(c[1], c[2], c[3])
        halo:SetPoint("TOPLEFT", b, "TOPLEFT", -HALO_OUT, HALO_OUT)
        halo:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", HALO_OUT, -HALO_OUT)
    end
    local frame = b:CreateTexture(nil, "BACKGROUND", nil, 0)
    frame:SetTexture(WHITE)
    frame:SetVertexColor(FRAME[1], FRAME[2], FRAME[3])
    frame:SetAllPoints(b)
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(look.texture)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("TOPLEFT", b, "TOPLEFT", INSET, -INSET)
    icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -INSET, INSET)
    local text = b:CreateFontString(nil, "OVERLAY")
    text:SetFont(T.FONT, textSize(look.size), "THICKOUTLINE")
    text:SetTextColor(1, 1, 1)
    text:SetPoint("CENTER")
    text:SetAlpha(look.timers and 1 or 0)
    b:SetDurationText(text)
    if not halo then return end
    local breath = halo:CreateAnimationGroup()
    breath:SetLooping("BOUNCE")
    local fade = breath:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(HALO_LOW)
    fade:SetDuration(BREATH)
    fade:SetSmoothing("IN_OUT")
    breath:Play()
    pcall(b.HookScript, b, "OnShow", function() pcall(breath.Play, breath) end)
end

function Overlay:Watch(list)
    self.list = list
    local look = { texture = self.texture, size = self.size or 1, timers = self.timers, glow = self.glow, color = self.color }
    for i, w in ipairs(list) do
        local d = self.displays[i]
        local set, sig = {}, table.concat(w.ids, ",")
        for _, id in ipairs(w.ids) do set[id] = true end
        if d and d.sig ~= sig then
            d:SetAuraGroupCandidateFilters("a", { includeSpellIDs = set })
            d.sig = sig
        end
        if not d then
            d = CreateFrame("AuraContainer", nil, self.root, "CustomAuraContainerTemplate")
            d:SetPoint("TOPLEFT", self.root, "TOPLEFT")
            d:EnableMouse(false)
            d.sig = sig
            d:AddAuraGroup("a", "HELPFUL", {
                maxFrameCount = 1,
                candidateFilters = { includeSpellIDs = set },
                initializeFrame = function(b) self:Dress(b, look) end,
                layout = { elementWidth = look.size, elementHeight = look.size },
            })
            self.displays[i] = d
        end
        d:SetUnit(w.unit)
        d:SetEnabled(true)
    end
    for i = #list + 1, #self.displays do self.displays[i]:SetEnabled(false) end
end

-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Layer = {}
Layer.__index = Layer
ns.SecretLayer = Layer

local T = ns.Theme
local WHITE = "Interface\\Buttons\\WHITE8X8"
local SPACING = 1

local function holder(parent, level)
    local f = CreateFrame("Frame", nil, parent)
    f:SetAllPoints(parent)
    f:SetFrameLevel(level)
    return f
end

local function bar(parent)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetOrientation("VERTICAL")
    b:SetStatusBarTexture(WHITE)
    b:SetMinMaxValues(0, 1)
    b:SetValue(0)
    return b
end

function Layer.New(icon)
    local f = icon.frame
    local level = f:GetFrameLevel() + 4
    local self = setmetatable({ icon = icon, slots = {} }, Layer)
    self.root = holder(f, level)
    self.grey = holder(self.root, level + 1)
    self.window = CreateFrame("Frame", nil, self.root)
    self.window:SetPoint("CENTER", f, "CENTER")
    self.window:SetClipsChildren(true)
    self.window:SetFrameLevel(level + 3)
    self.cooling = holder(self.window, level + 3)
    for s = 1, 2 do
        local slot = {}
        slot.gate = CreateFrame("StatusBar", nil, self.grey)
        slot.gate:SetAllPoints(icon.tex)
        slot.gate:SetMinMaxValues(0, 1)
        slot.gate:SetValue(0)
        slot.cool = bar(self.cooling)
        slot.coolText = slot.cool:CreateFontString(nil, "OVERLAY")
        slot.cool:GetStatusBarTexture():SetAlpha(0)
        slot.cool:SetPoint("BOTTOM", self.window, "BOTTOM")
        slot.coolText:SetPoint("TOP", slot.cool:GetStatusBarTexture(), "TOP")
        slot.coolText:SetJustifyH("CENTER")
        slot.coolText:SetJustifyV("TOP")
        slot.coolText:SetSpacing(SPACING)
        self.slots[s] = slot
    end
    self.overlay = ns.ActiveOverlay.New(self.root, level + 5)
    self.root:Hide()
    return self
end

-- Strips hang from secret-valued bar fills, so their own measurements come back secret; measure on a free string.
local measurer, heights = nil, {}

local function linePitch(fontSize)
    if not heights[fontSize] then
        measurer = measurer or CreateFrame("Frame", nil, UIParent):CreateFontString(nil, "OVERLAY")
        measurer:SetFont(T.FONT, fontSize, "OUTLINE")
        measurer:SetSpacing(SPACING)
        measurer:SetText("0")
        local one = measurer:GetStringHeight()
        measurer:SetText("0\n0")
        heights[fontSize] = measurer:GetStringHeight() - one
    end
    return heights[fontSize]
end

local function fontSize(size)
    return math.max(8, math.floor(size * 0.42))
end

function Layer:SetLook(texture, size)
    self.size = size
    for _, slot in ipairs(self.slots) do
        slot.gate:SetStatusBarTexture(texture)
        slot.gate:GetStatusBarTexture():SetDesaturated(true)
        slot.coolText:SetFont(T.FONT, fontSize(size), "OUTLINE")
        slot.coolText:SetWidth(size)
    end
    self.line = linePitch(fontSize(size))
    self.window:SetSize(size, self.line)
    self.overlay:SetLook(texture, size)
end

function Layer:Configure(cd)
    local labels = {}
    for k = 1, math.ceil(cd) do labels[k] = ns.LayoutRules.FormatRemaining(k) end
    local text = table.concat(labels, "\n")
    for _, slot in ipairs(self.slots) do
        slot.coolText:SetText(text)
        slot.cool:SetSize(self.size or 1, cd * (self.line or 1))
    end
end

function Layer:Watch(list)
    self.overlay:Watch(list)
end

function Layer:Write(s, v)
    local slot = self.slots[s]
    slot.gate:SetMinMaxValues(v.gateLo, v.gateHi)
    slot.gate:SetValue(v.stamp)
    slot.cool:SetMinMaxValues(v.coolLo, v.coolHi)
    slot.cool:SetValue(v.stamp)
end

function Layer:SetPhase(idle)
    self.cooling:SetAlpha(idle)
    self.grey:SetAlpha(idle)
end

function Layer:SetTimers(on)
    self.window:SetShown(on)
    self.overlay:SetTimers(on)
end

function Layer:Show(on)
    self.root:SetShown(on)
end

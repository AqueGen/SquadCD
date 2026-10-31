-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Layer = {}
Layer.__index = Layer
ns.SecretLayer = Layer

local T = ns.Theme
local WHITE = "Interface\\Buttons\\WHITE8X8"
local SPACING = 1
local BORDER = 2

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
    self.border = CreateFrame("Frame", nil, self.root, "BackdropTemplate")
    self.border:SetPoint("TOPLEFT", f, "TOPLEFT", -BORDER, BORDER)
    self.border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", BORDER, -BORDER)
    self.border:SetFrameLevel(level + 2)
    self.border:SetBackdrop({ edgeFile = WHITE, edgeSize = BORDER })
    self.border:SetBackdropBorderColor(T.gold[1], T.gold[2], T.gold[3], 1)
    self.border:SetAlpha(0)
    self.window = CreateFrame("Frame", nil, self.root)
    self.window:SetPoint("CENTER", f, "CENTER")
    self.window:SetClipsChildren(true)
    self.window:SetFrameLevel(level + 3)
    self.cooling = holder(self.window, level + 3)
    self.active = holder(self.window, level + 3)
    self.active:SetAlpha(0)
    for s = 1, 2 do
        local slot = {}
        slot.gate = CreateFrame("StatusBar", nil, self.grey)
        slot.gate:SetAllPoints(icon.tex)
        slot.gate:SetMinMaxValues(0, 1)
        slot.gate:SetValue(0)
        slot.cool = bar(self.cooling)
        slot.act = bar(self.active)
        slot.coolText = slot.cool:CreateFontString(nil, "OVERLAY")
        slot.actText = slot.act:CreateFontString(nil, "OVERLAY")
        for _, pair in ipairs({ { slot.cool, slot.coolText }, { slot.act, slot.actText } }) do
            local b, text = pair[1], pair[2]
            b:GetStatusBarTexture():SetAlpha(0)
            b:SetPoint("BOTTOM", self.window, "BOTTOM")
            text:SetPoint("TOP", b:GetStatusBarTexture(), "TOP")
            text:SetJustifyH("CENTER")
            text:SetJustifyV("TOP")
            text:SetSpacing(SPACING)
        end
        self.slots[s] = slot
    end
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

function Layer:SetLook(texture, size)
    self.size = size
    for _, slot in ipairs(self.slots) do
        slot.gate:SetStatusBarTexture(texture)
        slot.gate:GetStatusBarTexture():SetDesaturated(true)
        for _, text in ipairs({ slot.coolText, slot.actText }) do
            text:SetFont(T.FONT, math.max(8, math.floor(size * 0.42)), "OUTLINE")
            text:SetWidth(size)
        end
    end
    self.line = linePitch(math.max(8, math.floor(size * 0.42)))
    self.window:SetSize(size, self.line)
end

local function strip(b, text, span, line, width)
    if not span then
        text:SetText("")
        b:SetSize(width, line)
        return
    end
    local labels = {}
    for k = 1, math.ceil(span) do labels[k] = ns.LayoutRules.FormatRemaining(k) end
    text:SetText(table.concat(labels, "\n"))
    b:SetSize(width, span * line)
end

function Layer:Configure(cd, dur)
    for _, slot in ipairs(self.slots) do
        strip(slot.cool, slot.coolText, cd, self.line or 1, self.size or 1)
        strip(slot.act, slot.actText, dur, self.line or 1, self.size or 1)
    end
end

function Layer:Write(s, v)
    local slot = self.slots[s]
    slot.gate:SetMinMaxValues(v.gateLo, v.gateHi)
    slot.gate:SetValue(v.stamp)
    slot.cool:SetMinMaxValues(v.coolLo, v.coolHi)
    slot.cool:SetValue(v.stamp)
    if v.actLo then
        slot.act:SetMinMaxValues(v.actLo, v.actHi)
        slot.act:SetValue(v.stamp)
    end
end

function Layer:SetPhase(active, idle)
    self.border:SetAlpha(active)
    self.active:SetAlpha(active)
    self.cooling:SetAlpha(idle)
    self.grey:SetAlpha(idle)
end

function Layer:SetTimers(on)
    self.window:SetShown(on)
end

function Layer:Show(on)
    self.root:SetShown(on)
end

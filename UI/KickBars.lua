-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local KickBars = {}
KickBars.__index = KickBars
ns.KickBars = KickBars

local T = ns.Theme
local ICON, GAP, TRACK_W, TRACK_H, LETTERS = 20, 2, 130, 16, 10
local TRACK = { 0.114, 0.125, 0.145, 1 }
KickBars.W, KickBars.H = ICON + GAP + TRACK_W, ICON

function KickBars.New(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(KickBars.W, KickBars.H)
    local icon = ns.Icon.New(f)
    icon.frame:SetPoint("LEFT", f, "LEFT", 0, 0)
    local track = CreateFrame("Frame", nil, f, "BackdropTemplate")
    track:SetSize(TRACK_W, TRACK_H)
    track:SetPoint("LEFT", icon.frame, "RIGHT", GAP, 0)
    track:SetBackdrop(T.FLAT)
    track:SetBackdropColor(unpack(TRACK))
    track:SetBackdropBorderColor(0, 0, 0, 0)
    local fill = track:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetHeight(TRACK_H - 2)
    local name = track:CreateFontString(nil, "OVERLAY")
    name:SetFont(T.FONT, 10, "OUTLINE")
    name:SetPoint("LEFT", track, "LEFT", 4, 0)
    local value = track:CreateFontString(nil, "OVERLAY")
    value:SetFont(T.FONT, 10, "OUTLINE")
    value:SetPoint("RIGHT", track, "RIGHT", -4, 0)
    return setmetatable({ frame = f, icon = icon, track = track, fill = fill, name = name, value = value, buf = {} }, KickBars)
end

function KickBars:SetEntry(spell, member)
    self.spell = spell
    self.icon:SetSpell(spell, member, ICON)
    self.name:SetText(ns.LayoutRules.ShortName(member.name or member.class or "?", LETTERS))
    self.name:SetTextColor(1, 1, 1)
    local r, g, b = T.ClassColor(member.class)
    self.fill:SetColorTexture(r, g, b, 0.85)
    self.text, self.share, self.next = nil, nil, nil
end

function KickBars:Update(state, now, timers)
    self.icon:Update(state, now, false)
    local cooling = not state.ready
    local unknown = not cooling and state.unknown or false
    local duration = self.icon.duration or 0
    local share = unknown and 0 or cooling and duration > 0 and math.max(0, math.min(1, 1 - state.remaining / duration)) or 1
    if share ~= self.share then
        self.share = share
        self.fill:SetShown(share > 0)
        self.fill:SetWidth(math.max(1, share * (TRACK_W - 2)))
    end
    local text = cooling and (timers ~= false and ns.LayoutRules.FormatRemaining(state.remaining) or "") or unknown and "?" or "ready"
    if text ~= self.text then
        self.text = text
        self.value:SetText(text)
    end
end

function KickBars:SetNext(on)
    if on == self.next then return end
    self.next = on
    if on then
        self.track:SetBackdropBorderColor(unpack(T.gold))
    else
        self.track:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

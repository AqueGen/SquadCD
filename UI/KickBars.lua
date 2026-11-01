-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local KickBars = {}
KickBars.__index = KickBars
ns.KickBars = KickBars

local T = ns.Theme
local ICON, GAP, TRACK_W, TRACK_H, LETTERS = 20, 2, 130, 16, 10
local TRACK = { 0.114, 0.125, 0.145, 1 }
local RESULT = { hit = { 0.2, 0.8, 0.3 }, late = { 0.95, 0.8, 0.2 }, miss = { 0.45, 0.45, 0.45 }, cast = { 0.9, 0.9, 0.9 } }
local RESULT_TEXT = { hit = "kicked", late = "late", miss = "no hit", cast = "..." }
local DOWN = { 0.9, 0.15, 0.15, 1 }
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
    self.who = ns.LayoutRules.ShortName(member.name or member.class or "?", LETTERS)
    self.name:SetText(self.who)
    self.name:SetTextColor(1, 1, 1)
    self.own = member.unit == "player"
    self.guid = member.guid
    self.classColor = { T.ClassColor(member.class) }
    self.fill:SetColorTexture(self.classColor[1], self.classColor[2], self.classColor[3], 0.85)
    self.text, self.share, self.next, self.down, self.result = nil, nil, nil, nil, nil
end

function KickBars:Update(state, now, timers)
    self.icon:Update(state, now, false)
    local result
    if self.own then
        result = ns.Kicks.OwnResult(now)
    else
        result = ns.Kicks.HitResult(self.guid, now)
    end
    if result ~= self.result then
        self.result = result
        local c = RESULT[result] or self.classColor
        self.fill:SetColorTexture(c[1], c[2], c[3], 0.85)
        self.text = nil
    end
    local cooling = not state.ready
    local unknown = not cooling and state.unknown or false
    local duration = self.icon.duration or 0
    local share = unknown and 0 or cooling and duration > 0 and math.max(0, math.min(1, 1 - state.remaining / duration)) or 1
    if share ~= self.share then
        self.share = share
        self.fill:SetShown(share > 0)
        self.fill:SetWidth(math.max(1, share * (TRACK_W - 2)))
    end
    local text = self.result and RESULT_TEXT[self.result]
        or cooling and (timers ~= false and ns.LayoutRules.FormatRemaining(state.remaining) or "") or unknown and "?"
        or self.own and self.next and "your turn" or "ready"
    if text ~= self.text then
        self.text = text
        self.value:SetText(text)
    end
end

-- down: every kick on the line is cooling, so the party needs a stun or a knockback instead.
function KickBars:SetNext(on, down)
    if on == self.next and down == self.down then return end
    self.next, self.down = on, down
    self.text = nil
    if on then
        self.track:SetBackdropBorderColor(unpack(T.gold))
    elseif down then
        self.track:SetBackdropBorderColor(unpack(DOWN))
    else
        self.track:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

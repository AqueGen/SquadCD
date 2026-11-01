-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local KickBars = {}
KickBars.__index = KickBars
ns.KickBars = KickBars

local T = ns.Theme
local ICON, GAP, TRACK_W, TRACK_H, LETTERS = 20, 2, 130, 16, 10
local TRACK = { 0.114, 0.125, 0.145, 1 }
local RESULT = { hit = { 0.2, 0.8, 0.3 }, miss = { 0.85, 0.2, 0.2 }, cast = { 0.9, 0.9, 0.9 } }
local RESULT_TEXT = { hit = "kicked", miss = "missed", cast = "..." }
local MARK, MARKS = 12, "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
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
    local mark = track:CreateTexture(nil, "OVERLAY")
    mark:SetSize(MARK, MARK)
    mark:SetPoint("LEFT", track, "LEFT", 2, 0)
    mark:SetTexture(MARKS)
    mark:Hide()
    local name = track:CreateFontString(nil, "OVERLAY")
    name:SetFont(T.FONT, 10, "OUTLINE")
    name:SetPoint("LEFT", track, "LEFT", 4, 0)
    local value = track:CreateFontString(nil, "OVERLAY")
    value:SetFont(T.FONT, 10, "OUTLINE")
    value:SetPoint("RIGHT", track, "RIGHT", -4, 0)
    local target = track:CreateFontString(nil, "OVERLAY")
    target:SetFont(T.FONT, 10, "OUTLINE")
    target:SetPoint("LEFT", name, "RIGHT", 3, 0)
    target:SetPoint("RIGHT", value, "LEFT", -4, 0)
    target:SetJustifyH("LEFT")
    target:SetWordWrap(false)
    return setmetatable({ frame = f, icon = icon, track = track, fill = fill, mark = mark, name = name, target = target, value = value, buf = {} }, KickBars)
end

function KickBars:SetEntry(spell, member)
    self.spell = spell
    self.icon:SetSpell(spell, member, ICON)
    self.who = ns.LayoutRules.ShortName(member.name or member.class or "?", LETTERS)
    self.name:SetText(self.who)
    self.name:SetTextColor(1, 1, 1)
    self.own = member.unit == "player"
    self.classColor = { T.ClassColor(member.class) }
    self.fill:SetColorTexture(self.classColor[1], self.classColor[2], self.classColor[3], 0.85)
    self.text, self.share, self.next, self.result, self.focus = nil, nil, nil, nil, nil
    self.mark:Hide()
    self.target:SetText("")
    self.name:ClearAllPoints()
    self.name:SetPoint("LEFT", self.track, "LEFT", 4, 0)
end

-- Your focus: its raid mark and name next to your own kick bar, so the party sees which mob is yours.
function KickBars:ShowFocus()
    local index, target, secret = ns.Kicks.Focus()
    local key = secret and "secret" or tostring(index) .. ":" .. tostring(target)
    if key == self.focus and not secret then return end
    self.focus = key
    self.mark:SetShown(index ~= nil)
    if index then SetRaidTargetIconTexture(self.mark, index) end
    self.name:ClearAllPoints()
    self.name:SetPoint("LEFT", self.track, "LEFT", index and MARK + 4 or 4, 0)
    self.name:SetText(target and (self.who .. " >") or self.who)
    self.target:SetText(secret and target or target and ns.LayoutRules.ShortName(target, LETTERS) or "")
end

function KickBars:Update(state, now, timers)
    self.icon:Update(state, now, false)
    if self.own then
        self:ShowFocus()
        local result = ns.Kicks.OwnResult(now)
        if result ~= self.result then
            self.result = result
            local c = RESULT[result] or self.classColor
            self.fill:SetColorTexture(c[1], c[2], c[3], 0.85)
            self.text = nil
        end
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
        or cooling and (timers ~= false and ns.LayoutRules.FormatRemaining(state.remaining) or "") or unknown and "?" or "ready"
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

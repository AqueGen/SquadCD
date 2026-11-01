-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local KickBars = {}
KickBars.__index = KickBars
ns.KickBars = KickBars

local T = ns.Theme
local ICON, GAP, TRACK_W, TRACK_H, LETTERS = 20, 2, 130, 16, 10
local FOCUS_GAP, CAST_W = 10, 160
local CAST = { 1, 0.7, 0, 1 }
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
    local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
    box:SetHeight(TRACK_H)
    box:SetPoint("LEFT", track, "RIGHT", FOCUS_GAP, 0)
    box:SetBackdrop(T.FLAT)
    box:SetBackdropColor(unpack(TRACK))
    box:SetBackdropBorderColor(0, 0, 0, 0)
    local target = box:CreateFontString(nil, "OVERLAY")
    target:SetFont(T.FONT, 10, "OUTLINE")
    target:SetPoint("LEFT", track, "RIGHT", FOCUS_GAP + 4, 0)
    target:SetWordWrap(false)
    box:SetPoint("RIGHT", target, "RIGHT", 4, 0)
    box:Hide()
    local cast = CreateFrame("StatusBar", nil, f)
    cast:SetStatusBarTexture(T.FLAT.bgFile)
    cast:SetStatusBarColor(unpack(CAST))
    local castBack = cast:CreateTexture(nil, "BACKGROUND")
    castBack:SetAllPoints()
    castBack:SetColorTexture(unpack(TRACK))
    local spellIcon = cast:CreateTexture(nil, "OVERLAY")
    spellIcon:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -2)
    cast:SetPoint("LEFT", spellIcon, "RIGHT", 2, 0)
    local castName = cast:CreateFontString(nil, "OVERLAY")
    castName:SetPoint("LEFT", cast, "LEFT", 4, 0)
    castName:SetWidth(CAST_W - 8)
    castName:SetJustifyH("LEFT")
    castName:SetWordWrap(false)
    cast:Hide()
    return setmetatable({ frame = f, icon = icon, track = track, fill = fill, name = name, box = box, target = target,
        cast = cast, spellIcon = spellIcon, castName = castName, value = value, buf = {} }, KickBars)
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
    self.text, self.share, self.next, self.down, self.result, self.focus = nil, nil, nil, nil, nil, nil
    self.box:Hide()
    self.cast:Hide()
end

-- Your focus in a box right of your own kick bar, so the party sees which mob is yours; its cast under it.
function KickBars:ShowFocus(show, size, showCast)
    local key = show and ns.Kicks.FocusVersion() + size / 100 + (showCast and 0.5 or 0) or -1
    if key == self.focus then return end
    self.focus = key
    if show and size ~= self.focusSize then
        self.focusSize = size
        self.target:SetFont(T.FONT, size, "OUTLINE")
        self.box:SetHeight(size + 6)
        self.castName:SetFont(T.FONT, size, "OUTLINE")
        self.spellIcon:SetSize(size + 6, size + 6)
        self.cast:SetSize(CAST_W, size + 6)
    end
    local text = show and ns.Kicks.FocusText() or nil
    self.box:SetShown(text and true or false)
    self.target:SetText(text or "")
    self:ShowCast(text and showCast)
end

function KickBars:ShowCast(on)
    local duration, spell, icon, channel = nil, nil, nil, false
    if on then duration, spell, icon, channel = ns.Kicks.FocusCast() end
    if not duration then
        self.cast:Hide()
        return
    end
    local direction = channel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime
    self.cast:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, direction)
    self.castName:SetText(spell or "")
    self.spellIcon:SetTexture(icon)
    self.cast:Show()
end

function KickBars:Update(state, now, timers)
    self.icon:Update(state, now, false)
    local result
    if self.own then
        local l = ns.DB.layout
        self:ShowFocus(l.kickFocus, l.kickFocusSize, l.kickFocusCast)
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

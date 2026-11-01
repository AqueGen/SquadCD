-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local FocusPieces = {}
FocusPieces.__index = FocusPieces
ns.FocusPieces = FocusPieces

local T = ns.Theme
local TRACK = { 0.114, 0.125, 0.145, 1 }
local CAST = { 1, 0.7, 0, 1 }
local DEMO = {
    focus = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t Felonious Mage",
    cast = "Shadow Bolt",
    next = "|T136197:0|t Shadow Bolt 4\n|T136197:0|t Dark Mending ~12",
}

FocusPieces.NAMES = { focus = "Focus target", focuscast = "Focus cast", focusnext = "Focus next casts" }

function FocusPieces.Sizes(layout)
    local s = layout.kickFocusSize
    local h = s + 6
    return {
        focus = { w = layout.focusWidth, h = h },
        focuscast = { w = layout.focusWidth, h = h },
        focusnext = { w = 12 * s, h = 3 * (s + 3) + 4 },
    }
end

local function text(parent)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(T.FONT, 10, "OUTLINE")
    fs:SetJustifyH("LEFT")
    return fs
end

local function backed(f, on)
    if on then f:SetBackdropColor(unpack(TRACK)) else f:SetBackdropColor(0, 0, 0, 0) end
end

function FocusPieces.New()
    return setmetatable({ frames = {} }, FocusPieces)
end

-- Builds the piece's content once per container frame.
function FocusPieces:Attach(key, f)
    if self.frames[key] == f then return end
    self.frames[key] = f
    f:SetBackdrop(T.FLAT)
    f:SetBackdropBorderColor(0, 0, 0, 0)
    backed(f, false)
    f:SetClipsChildren(true)
    if key == "focus" then
        self.target = text(f)
        self.target:SetPoint("LEFT", f, "LEFT", 4, 0)
        self.target:SetWordWrap(false)
    elseif key == "focuscast" then
        self.spellIcon = f:CreateTexture(nil, "OVERLAY")
        self.spellIcon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        self.bar = CreateFrame("StatusBar", nil, f)
        self.bar:SetStatusBarTexture(T.FLAT.bgFile)
        self.bar:SetStatusBarColor(unpack(CAST))
        self.bar:SetPoint("TOPLEFT", self.spellIcon, "TOPRIGHT", 2, 0)
        self.bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        self.castName = text(self.bar)
        self.castName:SetPoint("LEFT", self.bar, "LEFT", 4, 0)
        self.castName:SetWordWrap(false)
    else
        self.upcoming = text(f)
        self.upcoming:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -2)
    end
    self.version = nil
end

function FocusPieces:Apply(layout)
    local s = layout.kickFocusSize
    if self.target then self.target:SetFont(T.FONT, s, "OUTLINE") end
    if self.castName then
        self.castName:SetFont(T.FONT, s, "OUTLINE")
        self.spellIcon:SetSize(s + 6, s + 6)
        self.castName:SetWidth(math.max(1, layout.focusWidth - s - 16))
    end
    if self.upcoming then self.upcoming:SetFont(T.FONT, s, "OUTLINE") end
    self.version, self.upcomingAt = nil, nil
end

function FocusPieces:ShowCast(f, demo)
    if demo then
        self.bar:SetMinMaxValues(0, 1)
        self.bar:SetValue(0.6)
        self.castName:SetText(DEMO.cast)
        self.spellIcon:SetTexture(136197)
        self.bar:Show()
        self.spellIcon:Show()
        backed(f, true)
        return
    end
    local duration, spell, icon, channel = ns.Kicks.FocusCast()
    self.bar:SetShown(duration and true or false)
    self.spellIcon:SetShown(duration and true or false)
    backed(f, duration and true or false)
    if not duration then return end
    local direction = channel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime
    self.bar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, direction)
    self.castName:SetText(spell or "")
    self.spellIcon:SetTexture(icon)
end

-- demo: settings preview and edit mode show sample content instead of the live focus.
function FocusPieces:Update(now, demo)
    local version = demo and -1 or ns.Kicks.FocusVersion()
    if version ~= self.version then
        self.version = version
        local f = self.frames.focus
        if f and self.target then
            local label = demo and DEMO.focus or ns.Kicks.FocusText()
            self.target:SetText(label or "")
            backed(f, label and true or false)
        end
        f = self.frames.focuscast
        if f and self.bar then self:ShowCast(f, demo) end
    end
    local f = self.frames.focusnext
    if not (f and self.upcoming) or (self.upcomingAt and now - self.upcomingAt < 0.2) then return end
    self.upcomingAt = now
    local label = demo and DEMO.next or ns.Kicks.UpcomingText(ns.Kicks.FocusUpcoming(3), now)
    if label == self.upcomingText then return end
    self.upcomingText = label
    self.upcoming:SetText(label or "")
    backed(f, label and true or false)
end

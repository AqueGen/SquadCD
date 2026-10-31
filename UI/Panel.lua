local _, ns = ...

local Panel = {}
ns.Panel = Panel

local T = ns.Theme
local PAD, LABEL_W, GAP, NAME_H = 6, 64, 4, 11

local LABELS = {
    Personal = "Defensives", Burst = "Burst", Racial = "Racials", Potion = "Potions",
    External = "Externals", Kick = "Kicks", Stun = "Stuns", CC = "CC", Group = "Raid CDs",
    Dispel = "Dispels", Purge = "Purges", Movement = "Movement",
}

local UNKNOWN = { ready = true, remaining = 0, charges = 1, maybe = false }

local frame
local lines, active = {}, 0

local function ensure()
    if frame then return frame end
    frame = CreateFrame("Frame", "HuddlePanel", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    ns.Theme.MakeMovable(frame, function() return ns.DB.panel.locked end, function(point)
        ns.DB.panel.point = point
        Panel.Place()
    end)
    return frame
end

local function line(i)
    if not lines[i] then
        local label = frame:CreateFontString(nil, "OVERLAY")
        label:SetFont(T.FONT, 11, "")
        label:SetTextColor(unpack(T.muted))
        label:SetJustifyH("LEFT")
        label:SetWidth(LABEL_W - 4)
        lines[i] = { label = label, icons = {}, entries = {} }
    end
    return lines[i]
end

function Panel.Place()
    local p = ns.DB.panel.point
    frame:ClearAllPoints()
    frame:SetPoint(p[1], UIParent, p[1], p[2], p[3])
end

function Panel.Build(groups)
    ensure()
    local size = ns.DB.panel.size
    local lineH = size + NAME_H + GAP
    for i = #groups + 1, #lines do
        lines[i].label:Hide()
        for _, icon in ipairs(lines[i].icons) do icon.frame:Hide() end
    end
    active = #groups
    if active == 0 then
        frame:Hide()
        return
    end
    local widest = 0
    for i, g in ipairs(groups) do
        local l = line(i)
        local top = -PAD - (i - 1) * lineH
        l.label:SetText(LABELS[g.type] or g.type)
        l.label:ClearAllPoints()
        l.label:SetPoint("TOPLEFT", PAD, top - (size - 11) / 2)
        l.label:Show()
        l.top, l.entries = top, g.entries
        for k, e in ipairs(g.entries) do
            local icon = l.icons[k] or ns.Icon.New(frame)
            l.icons[k] = icon
            icon:SetSpell(e.spell, e.member, size)
            icon:SetLabel(ns.LayoutRules.ShortName(e.member.name or e.member.class, 4), T.ClassColor(e.member.class))
            icon.frame:Show()
        end
        for k = #g.entries + 1, #l.icons do l.icons[k].frame:Hide() end
        widest = math.max(widest, #g.entries)
    end
    local locked = ns.DB.panel.locked
    T.Panel(frame)
    if not locked then frame:SetBackdropBorderColor(unpack(T.gold)) end
    frame:EnableMouse(not locked)
    frame:SetSize(PAD * 2 + LABEL_W + widest * (size + GAP) - GAP, PAD * 2 + active * lineH - GAP)
    Panel.Place()
    frame:Show()
end

function Panel.Update(tracker, now)
    local size = ns.DB.panel.size
    for i = 1, active do
        local l = lines[i]
        local states = {}
        for k, e in ipairs(l.entries) do
            local s = tracker:State(e.member.guid, e.spell.id) or UNKNOWN
            states[k] = { ready = s.ready, remaining = s.remaining, maybe = s.maybe, state = s, icon = l.icons[k] }
        end
        for k, s in ipairs(ns.LayoutRules.Order(states)) do
            s.icon:Update(s.state, now)
            s.icon.frame:ClearAllPoints()
            s.icon.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + LABEL_W + (k - 1) * (size + GAP), l.top)
        end
    end
end

function Panel.Hide()
    if frame then frame:Hide() end
    active = 0
end

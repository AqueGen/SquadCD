-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local PanelPreview = {}
ns.PanelPreview = PanelPreview

local INTERVAL = 0.1
local MEMBERS = 5
local CAPTION = "Preview: the Demo party, 5 members"
local EMPTY = "Nothing to show: every type is off or hidden."
local FRAME_W, FRAME_H, FRAME_GAP, ROOM, ROOM_V, PANEL_GAP = 120, 46, 2, 150, 40, 16

local pane, host, panelHost, panel, rows, source
local frames, byUnit = {}, {}
local listening = false
local elapsed = 0
local sight = { live = false, plain = true, secret = {} }

local spare
local anchors = {
    FrameFor = function(unit) return byUnit[unit], false end,
    SizeOf = function() return FRAME_W, FRAME_H end,
    Stack = function()
        spare = spare or CreateFrame("Frame", nil, host, "BackdropTemplate")
        return spare
    end,
    PlaceStack = function() end,
}

local function update()
    sight.timers = ns.DB.layout.timers
    local now = GetTime()
    panel.Update(source.tracker, now, sight)
    rows.Update(source.tracker, now, sight)
end

local function tick(_, dt)
    elapsed = elapsed + dt
    if elapsed < INTERVAL then return end
    elapsed = 0
    update()
end

function PanelPreview.Stop()
    if pane then pane:SetScript("OnUpdate", nil) end
end

local function partyFrame(i)
    if frames[i] then return frames[i] end
    local f = CreateFrame("Frame", nil, host)
    f:SetSize(FRAME_W, FRAME_H)
    f.fill = f:CreateTexture(nil, "BACKGROUND")
    f.fill:SetAllPoints(f)
    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.name:SetPoint("TOP", f, "TOP", 0, -4)
    frames[i] = f
    return f
end

local function placeParty(members, shown, x, y)
    wipe(byUnit)
    for i, m in ipairs(members) do
        local f = partyFrame(i)
        local r, g, b = ns.Theme.ClassColor(m.class)
        f.fill:SetColorTexture(r, g, b, 0.55)
        f.name:SetText(m.name)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", host, "TOPLEFT", x, -(y + (i - 1) * (FRAME_H + FRAME_GAP)))
        f:SetShown(shown)
        byUnit[m.unit] = f
    end
end

local function anyGroup(list)
    for _, row in ipairs(list) do
        for _, runs in pairs(row.groups) do
            if #runs > 0 then return true end
        end
    end
    return false
end

local function rooms(layout)
    local used = {}
    for _, g in ipairs(layout.groups) do
        if g.shown and #g.types > 0 then used[g.side] = true end
    end
    return used.Left and ROOM or 0, used.Right and ROOM or 0, used.Above and ROOM_V or 0, used.Below and ROOM_V or 0
end

local function rebuild(fresh)
    if not pane or not pane:IsVisible() then return end
    if fresh or not source then source = ns.Demo.Source(MEMBERS) end
    local lines, routed = ns.Display.Route(source.members)
    local party = anyGroup(routed)
    local pw, ph = panel.Build(lines)
    local left, right, top, bottom = rooms(ns.DB.layout)
    local partyW = party and left + FRAME_W + right or 0
    local partyH = party and top + MEMBERS * FRAME_H + (MEMBERS - 1) * FRAME_GAP + bottom or 0
    local w = math.max(partyW, pw)
    placeParty(source.members, party, (w - partyW) / 2 + left, top)
    if party then rows.Build(routed, true) else rows.Hide() end
    if #lines == 0 and not party then
        PanelPreview.Stop()
        pane:SetOff(EMPTY)
        return
    end
    local gap = party and ph > 0 and PANEL_GAP or 0
    panelHost:ClearAllPoints()
    panelHost:SetPoint("TOPLEFT", host, "TOPLEFT", (w - pw) / 2, -(partyH + gap))
    panelHost:SetSize(math.max(pw, 1), math.max(ph, 1))
    local h = partyH + gap + ph
    host:SetSize(w, h)
    pane:SetOff(nil)
    pane:Fit(host, w, h)
    update()
    elapsed = 0
    pane:SetScript("OnUpdate", tick)
end

function PanelPreview.Attach(target)
    if pane == target then return end
    PanelPreview.Stop()
    pane = target
    host = CreateFrame("Frame", nil, pane.stage)
    panelHost = CreateFrame("Frame", nil, host)
    panel = ns.Panel.New({ parent = panelHost })
    rows = ns.Rows.New({ parent = host, anchors = anchors })
    pane:SetCaption(CAPTION)
    pane:HookScript("OnHide", PanelPreview.Stop)
    if not listening then
        listening = true
        ns.Display.OnChanged(function() rebuild(false) end)
    end
end

function PanelPreview.Refresh()
    rebuild(true)
end

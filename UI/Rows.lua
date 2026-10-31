-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Rows = {}
ns.Rows = Rows

local T = ns.Theme
local Grid, Model = ns.LayoutGrid, ns.LayoutModel
local SLOT_W, PAD, ICON_GAP, RING, TAB_GAP, STACK_GAP = 60, 4, 2, 2, 2, 2
local TAB = { None = 0, Icon = 16, Glyph = 11, Short = 30 }

local members, slots, active = {}, {}, 0
local outlined

local function holder(i, gi)
    members[i] = members[i] or {}
    local g = members[i][gi]
    if not g then
        g = { frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate"), icons = {}, tabs = {} }
        g.frame:SetFrameStrata("MEDIUM")
        members[i][gi] = g
    end
    return g
end

local function slot(stack, i)
    if not slots[i] then
        local f = CreateFrame("Frame", nil, stack)
        local name = f:CreateFontString(nil, "OVERLAY")
        name:SetFont(T.FONT, 11, "OUTLINE")
        name:SetPoint("LEFT", 4, 0)
        f.name = name
        slots[i] = f
    end
    return slots[i]
end

local function layoutStack(stacked)
    local stack = ns.Anchors.Stack()
    local byGuid = {}
    for _, f in ipairs(slots) do f:Hide() end
    if #stacked == 0 then
        stack:Hide()
        return byGuid
    end
    T.Panel(stack)
    local editing = ns.EditMode.Panels()
    if editing then stack:SetBackdropBorderColor(unpack(T.gold)) end
    stack:EnableMouse(editing)
    local y = PAD
    for i, s in ipairs(stacked) do
        local f = slot(stack, i)
        f:SetSize(SLOT_W, s.height)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", PAD, -y)
        f.name:SetText(ns.LayoutRules.ShortName(s.member.name or s.member.class, 8))
        f.name:SetTextColor(T.ClassColor(s.member.class))
        f:Show()
        byGuid[s.member.guid] = f
        y = y + s.height + STACK_GAP
    end
    stack:SetSize(SLOT_W + PAD * 2, y - STACK_GAP + PAD)
    ns.Anchors.PlaceStack()
    stack:Show()
    return byGuid
end

local function measure(row, g, gi, layout, isStack, fw, fh)
    local look = Model.LookOf(layout, g, true)
    local size = look.iconSize
    local side = g.side
    if isStack and (side == "Above" or side == "Below") then side = "Right" end
    local counts, total = {}, 0
    for k, run in ipairs(row.groups[gi]) do
        counts[k] = #run.spells
        total = total + #run.spells
    end
    if total == 0 then return nil end
    local tabW = TAB[look.labels] or 0
    local lead = tabW > 0 and tabW + TAB_GAP or 0
    local shape = g.shape
    local gap = g.gap or ICON_GAP
    if layout.memberFit and not isStack then
        shape = Grid.FitShape(shape, side, total, size, size, lead, fw, fh, gap)
    end
    local tabs = Grid.Tabs(counts, shape.perLine)
    local cells = {}
    for k = 1, total do cells[k] = { w = size + (tabs[k] and lead or 0), h = size } end
    local rects, w, h = Grid.PlaceMemberRow(cells, shape, side, isStack and 0 or fh, gap)
    return {
        gi = gi, group = g, look = look, size = size, side = side, tabW = tabW, tabs = tabs, rects = rects,
        corner = Grid.MemberOrigin(shape.origin, side), w = w + 2 * RING, h = h + 2 * RING,
        offsetX = g.offsetX, offsetY = g.offsetY,
    }
end

local function draw(i, m, row, anchor, away)
    local holderOf = holder(i, m.gi)
    local f = holderOf.frame
    holderOf.look = m.look
    T.Backdrop(f, m.look)
    f:SetSize(m.w, m.h)
    f:ClearAllPoints()
    local beside = m.side == "Left" or m.side == "Right"
    local point, relative, x, y = Grid.MemberAnchor(m.side, m.corner, away, beside and m.offsetY or m.offsetX)
    f:SetPoint(point, anchor, relative, x, y)
    local mirrored = m.corner == "TopRight" or m.corner == "BottomRight"
    local k = 0
    local used = 0
    for _, run in ipairs(row.groups[m.gi]) do
        for _, spell in ipairs(run.spells) do
            k = k + 1
            local r = m.rects[k]
            local icon = holderOf.icons[k] or ns.Icon.New(f)
            holderOf.icons[k] = icon
            icon:SetSpell(spell, row.member, m.size)
            icon.guid, icon.own = row.member.guid, row.own
            local iconX = r.x
            if m.tabs[k] and m.tabW > 0 then
                used = used + 1
                local tab = holderOf.tabs[used] or ns.Icon.NewTab(f)
                holderOf.tabs[used] = tab
                tab:Set(run.type, m.look.labels)
                tab.frame:SetSize(m.tabW, m.size)
                tab.frame:ClearAllPoints()
                local tabX = mirrored and r.x + m.size + TAB_GAP or r.x
                if not mirrored then iconX = r.x + m.tabW + TAB_GAP end
                tab.frame:SetPoint("TOPLEFT", f, "TOPLEFT", RING + tabX, -(RING + r.y))
                tab.text:ClearAllPoints()
                tab.text:SetPoint("CENTER", tab.frame, "CENTER", 0, 0)
                tab.frame:Show()
            end
            icon.frame:ClearAllPoints()
            icon.frame:SetPoint("TOPLEFT", f, "TOPLEFT", RING + iconX, -(RING + r.y))
            icon.frame:Show()
        end
    end
    for j = k + 1, #holderOf.icons do holderOf.icons[j].frame:Hide() end
    for j = used + 1, #holderOf.tabs do holderOf.tabs[j].frame:Hide() end
    holderOf.count = k
    f:Show()
end

local function hideMember(i, keep)
    for gi, g in pairs(members[i] or {}) do
        if not keep[gi] then
            g.frame:Hide()
            g.count = 0
        end
    end
end

function Rows.Build(rows, noStack)
    outlined = nil
    local layout = ns.DB.layout
    local plan, stacked = {}, {}
    for i, row in ipairs(rows) do
        local anchor, isStack = ns.Anchors.FrameFor(row.member.unit, noStack)
        local fw, fh = 0, 0
        if anchor and not isStack then fw, fh = ns.Anchors.SizeOf(anchor) end
        local list, height = {}, 0
        for gi, g in ipairs(layout.groups) do
            if anchor and row.groups[gi] then
                local m = measure(row, g, gi, layout, isStack, fw, fh)
                if m then
                    list[#list + 1] = m
                    height = math.max(height, m.h)
                end
            end
        end
        plan[i] = { anchor = not isStack and anchor or nil, list = list }
        if isStack then stacked[#stacked + 1] = { member = row.member, height = math.max(height, layout.memberLook.iconSize) } end
    end
    local stackSlots = layoutStack(stacked)
    for _, i in ipairs(Grid.Surplus(members, #rows)) do hideMember(i, {}) end
    active = #rows
    for i, row in ipairs(rows) do
        local p = plan[i]
        local anchor = p.anchor or stackSlots[row.member.guid]
        local keep = {}
        local away = {}
        for _, side in ipairs({ "Left", "Right", "Above", "Below" }) do
            for k, v in pairs(Grid.MemberStack(p.list, side)) do away[k] = v end
        end
        for k, m in ipairs(p.list) do
            draw(i, m, row, anchor, away[k])
            keep[m.gi] = true
        end
        hideMember(i, keep)
    end
end

function Rows.Update(tracker, now, sight)
    for i = 1, active do
        for _, g in pairs(members[i] or {}) do
            for k = 1, g.count or 0 do
                local icon = g.icons[k]
                local state = tracker:State(icon.guid, icon.spell.id, icon.buf)
                if state then
                    state.unknown = state.ready and ns.LayoutRules.Unknown(icon.spell.id, icon.own, sight.plain, sight.secret)
                end
                icon:Update(state, now, sight.timers)
            end
        end
    end
end

function Rows.Holder(gi)
    local g = members[1] and members[1][gi]
    if g and g.frame:IsShown() then return g.frame end
end

function Rows.Outline(gi)
    if gi == outlined then return end
    for i = 1, active do
        for k, g in pairs(members[i] or {}) do
            if g.look and k == outlined then T.Backdrop(g.frame, g.look) end
            if k == gi then g.frame:SetBackdropBorderColor(unpack(T.gold)) end
        end
    end
    outlined = gi
end

function Rows.Hide()
    for i in pairs(members) do hideMember(i, {}) end
    active = 0
    ns.Anchors.Stack():Hide()
end

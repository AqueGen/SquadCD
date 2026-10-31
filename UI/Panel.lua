-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Panel = {}
ns.Panel = Panel

local T = ns.Theme
local Grid, Model = ns.LayoutGrid, ns.LayoutModel
local PAD, LINE_GAP, CELL_GAP, NAME_H, GLYPH_TAB, ICON_TAB, LABEL_PAD = 6, 6, 2, 11, 11, 16, 3
local NEXT = { Kick = true, Control = true, Stun = true, CC = true, External = true, Group = true }

local UNKNOWN = { ready = true, remaining = 0, recharge = 0, charges = 1, maybe = false, talentsKnown = true }

local function line(c, i)
    if not c.lines[i] then
        c.lines[i] = { tab = ns.Icon.NewTab(c.frame), icons = {}, bars = {}, states = {}, sorted = {}, placed = {}, cells = {} }
    end
    return c.lines[i]
end

local function hideLine(l)
    l.tab.frame:Hide()
    for _, w in ipairs(l.icons) do w.frame:Hide() end
    for _, w in ipairs(l.bars) do w.frame:Hide() end
    l.count = 0
end

local function apply(w, e)
    w.entry = e
    if w.bars then
        w:SetEntry(e.spell, e.member)
        return 0
    end
    w:SetSpell(e.spell, e.member, w.size)
    return w:SetLabel(ns.LayoutRules.ShortName(e.member.name or e.member.class or "?", w.letters), T.ClassColor(e.member.class))
end

local function widgets(c, l, list, bars, size, letters, collapse)
    local pool = bars and l.bars or l.icons
    local other = bars and l.icons or l.bars
    for _, w in ipairs(other) do w.frame:Hide() end
    local widest = size
    wipe(l.states)
    wipe(l.placed)
    local groups = collapse and Grid.ByMember(list) or {}
    if not collapse then
        for k, e in ipairs(list) do groups[k] = { e } end
    end
    for k, alts in ipairs(groups) do
        local e = alts[1]
        local w = pool[k] or (bars and ns.KickBars.New(c.frame) or ns.Icon.New(c.frame))
        pool[k] = w
        w.buf.widget = w
        w.alts, w.bars, w.size, w.letters = alts, bars, size, letters
        for _, a in ipairs(alts) do a.buf = a.buf or {} end
        w.buf.role = Grid.RoleOf(e.member.spec)
        w.buf.classId = Grid.ClassId(e.member.class)
        l.states[k] = w.buf
        widest = math.max(widest, apply(w, e))
        w.frame:Show()
    end
    for k = #groups + 1, #pool do pool[k].frame:Hide() end
    l.widgets, l.count = pool, #groups
    if bars then return ns.KickBars.W, ns.KickBars.H end
    return widest, size + 1 + NAME_H
end

local function stackShape(layout, key, lines)
    if key == "panel" then return layout.panelShape end
    return lines[1].section.shape or layout.panelShape
end

local function fill(c, key, list, layout)
    local shapeOf = stackShape(layout, key, list)
    local across = shapeOf.axis == "Columns"
    local right = shapeOf.origin == "TopRight" or shapeOf.origin == "BottomRight"
    local bottom = shapeOf.origin == "BottomLeft" or shapeOf.origin == "BottomRight"
    local built, labelW = {}, 0
    for i, item in ipairs(list) do
        local l = line(c, i)
        local look = Model.LookOf(layout, item.section)
        local bars = Model.Bars(layout, item.type)
        local cellW, cellH = widgets(c, l, item.entries, bars, look.iconSize, look.nameLetters, item.type == "Kick")
        local cells = {}
        for k = 1, l.count do cells[k] = { w = cellW, h = cellH } end
        l.type, l.shape, l.labels, l.section = item.type, Model.LineShape(layout, item.section, item.type), look.labels, item.section
        local rects, w, h = Grid.Place(cells, l.shape, CELL_GAP)
        l.rects = rects
        l.head = bars and ns.KickBars.H or look.iconSize
        if look.labels ~= "None" then
            labelW = math.max(labelW, l.tab:Set(item.type, look.labels))
        end
        built[i] = { w = w, h = h }
    end
    for i = #list + 1, #c.lines do hideLine(c.lines[i]) end
    local sizes = {}
    for i in ipairs(list) do
        local l = c.lines[i]
        local tab
        if l.labels == "Icon" then
            tab = across and { w = ICON_TAB, h = ICON_TAB } or { w = ICON_TAB, h = l.head }
        elseif l.labels == "Glyph" then
            tab = across and { w = GLYPH_TAB, h = GLYPH_TAB } or { w = GLYPH_TAB, h = l.head }
        elseif l.labels ~= "None" then
            tab = across and { w = labelW + 2 * LABEL_PAD, h = GLYPH_TAB + 2 } or { w = labelW + 2 * LABEL_PAD, h = l.head }
        end
        local w, h, tabRect, area = Grid.Line(tab, built[i], across, right, bottom)
        l.tabRect, l.area = tabRect, area
        sizes[i] = { w = w, h = h }
    end
    local placed, w, h = Grid.PlaceSections(sizes, shapeOf, LINE_GAP)
    for i, at in ipairs(placed) do
        local l = c.lines[i]
        local x0, y0 = PAD + at.x, PAD + at.y
        if l.tabRect then
            local t = l.tabRect
            l.tab.frame:ClearAllPoints()
            l.tab.frame:SetPoint("TOPLEFT", c.frame, "TOPLEFT", x0 + t.x, -(y0 + t.y))
            l.tab.frame:SetSize(t.w, t.h)
            l.tab.text:ClearAllPoints()
            if across then
                l.tab.text:SetPoint(right and "RIGHT" or "LEFT", l.tab.frame, right and "RIGHT" or "LEFT", right and -LABEL_PAD or LABEL_PAD, 0)
            else
                l.tab.text:SetPoint("CENTER", l.tab.frame, bottom and "BOTTOM" or "TOP", 0, bottom and l.head / 2 or -l.head / 2)
            end
            l.tab.frame:Show()
        else
            l.tab.frame:Hide()
        end
        for k, r in ipairs(l.rects) do
            l.cells[k] = { x = x0 + l.area.x + r.x, y = y0 + l.area.y + r.y }
        end
    end
    return w + 2 * PAD, h + 2 * PAD
end

local function nameOf(section)
    local names = {}
    for i, t in ipairs(section.types) do names[i] = ns.LayoutRules.LABELS[t] or t end
    return table.concat(names, ", ")
end

local function fallback(buf)
    for k, v in pairs(UNKNOWN) do buf[k] = v end
    return buf
end

local function dead(unit)
    if not unit then return false end
    local v = UnitIsDeadOrGhost(unit)
    return not issecretvalue(v) and v == true
end

local states, cds = {}, {}

local function new(opts)
    local self = {}
    local preview = opts.parent ~= UIParent
    local main
    local windows = {}
    local shown = {}
    local roleOrder, classOrder = {}, {}
    local containers, positions = {}, {}

    local function newContainer(name)
        local f = CreateFrame("Frame", name, opts.parent, "BackdropTemplate")
        if not preview then
            f:SetFrameStrata("MEDIUM")
            f:SetClampedToScreen(true)
        end
        return { frame = f, lines = {} }
    end

    local function mainContainer()
        if main then return main end
        main = newContainer(opts.named and "SquadCDPanel" or nil)
        return main
    end

    local function window(i)
        windows[i] = windows[i] or newContainer(nil)
        return windows[i]
    end

    local function pickable(frame, target)
        frame.pick = target
        if frame.pickReady then return end
        frame.pickReady = true
        frame:EnableMouse(true)
        frame:SetScript("OnEnter", function(self) opts.pick.hover(self.pick, self) end)
        frame:SetScript("OnLeave", function() opts.pick.hover(nil) end)
        frame:SetScript("OnMouseUp", function(self) opts.pick.click(self.pick) end)
    end

    local function sectionTarget(layout, section)
        for i, s in ipairs(layout.sections) do
            if s == section then return { page = "panels", key = "section:" .. i, label = "Section " .. i .. ": " .. nameOf(s) } end
        end
    end

    local function placeOf(section, groups)
        local pos = section.pos
        if preview and pos and not (pos.dockTo and groups[pos.dockTo]) then return nil end
        return pos
    end

    function self.Build(list)
        local layout = ns.DB.layout
        roleOrder, classOrder = Model.RoleOrder(layout), layout.classOrder
        local groups, order, sectionOf = {}, {}, {}
        for _, item in ipairs(list) do
            local key = Model.OwnWindow(layout, item.section) and item.section.id or "panel"
            if not groups[key] then
                groups[key] = {}
                order[#order + 1] = key
                sectionOf[key] = item.section
            end
            table.insert(groups[key], item)
        end
        wipe(shown)
        local sizes, frames, nextWindow = {}, {}, 1
        for _, key in ipairs(order) do
            local c
            if key == "panel" then
                c = mainContainer()
            else
                c = window(nextWindow)
                nextWindow = nextWindow + 1
            end
            local w, h = fill(c, key, groups[key], layout)
            sizes[key], frames[key] = { w = w, h = h }, c
            shown[#shown + 1] = c
        end
        if not groups.panel and main then main.frame:Hide() end
        for i = nextWindow, #windows do windows[i].frame:Hide() end

        local scr = ns.Docking.Screen()
        local loose = {}
        for _, key in ipairs(order) do
            if key ~= "panel" and not placeOf(sectionOf[key], groups) then loose[#loose + 1] = sizes[key] end
        end
        local _, blockW, blockH = Grid.PlaceSections(loose, layout.panelShape, ns.Docking.GAP)
        local start = preview and { x = 0, y = 0 } or ns.Docking.FromPoint(layout.panel.point, sizes.panel or { w = blockW, h = blockH }, scr)
        positions = { panel = start }
        local chain = layout.panelShape.axis == "Columns" and "Right" or "Below"
        local previous = sizes.panel and "panel" or nil
        for _, key in ipairs(order) do
            if key ~= "panel" then
                positions[key] = placeOf(sectionOf[key], groups)
                    or { x = positions.panel.x, y = positions.panel.y, dockTo = previous, side = previous and chain, offset = previous and 0 }
                previous = key
            end
        end
        local rects = ns.Docking.Resolve(positions, sizes, not preview and scr or nil)
        local x0, y0, x1, y1 = 0, 0, 0, 0
        if preview and #order > 0 then
            x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
            for _, key in ipairs(order) do
                local r = rects[key]
                x0, y0 = math.min(x0, r.x), math.min(y0, r.y)
                x1, y1 = math.max(x1, r.x + r.w), math.max(y1, r.y + r.h)
            end
        end
        wipe(containers)
        for _, key in ipairs(order) do
            local c = frames[key]
            local r = rects[key]
            local f = c.frame
            local look = key == "panel" and layout.panelLook or Model.LookOf(layout, sectionOf[key])
            T.Backdrop(f, look)
            if opts.pick then
                pickable(f, key == "panel" and { page = "panels", key = "look", label = "Panel look and shape" } or sectionTarget(layout, sectionOf[key]))
                for _, l in ipairs(c.lines) do
                    if l.section and (l.count or 0) > 0 then pickable(l.tab.frame, sectionTarget(layout, l.section)) end
                end
            else
                f:EnableMouse(false)
            end
            f:SetSize(r.w, r.h)
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", opts.parent, "TOPLEFT", r.x - x0, -(r.y - y0))
            f:Show()
            containers[#containers + 1] = { key = key, frame = f, name = key == "panel" and "Panel" or nameOf(sectionOf[key]) }
        end
        return x1 - x0, y1 - y0
    end

    function self.Containers()
        return containers
    end

    function self.Positions()
        return positions
    end

    function self.Update(tracker, now, sight)
        for _, c in ipairs(shown) do
            for i = 1, #c.lines do
                local l = c.lines[i]
                if (l.count or 0) > 0 then
                    for k = 1, l.count do
                        local w = l.widgets[k]
                        local alts = w.alts
                        if #alts > 1 then
                            wipe(states)
                            wipe(cds)
                        end
                        for a = 1, #alts do
                            local e = alts[a]
                            local buf = #alts == 1 and w.buf or e.buf
                            if not tracker:State(e.member.guid, e.spell.id, buf) then fallback(buf) end
                            buf.unknown = buf.ready and ns.LayoutRules.Unknown(e.spell.id, e.own, sight.plain, sight.secret)
                            buf.dead = sight.live and dead(e.member.unit)
                            if #alts > 1 then states[a], cds[a] = buf, ns.Spells[e.spell.id] and ns.Spells[e.spell.id].cd or 0 end
                        end
                        if #alts > 1 then
                            local at = Grid.Best(states, cds)
                            if alts[at] ~= w.entry then apply(w, alts[at]) end
                            for key, v in pairs(states[at]) do w.buf[key] = v end
                        end
                    end
                    local sorted = Grid.Sort(l.states, l.shape, roleOrder, l.sorted, classOrder)
                    local nextAt = NEXT[l.type] and Grid.Next(sorted, roleOrder, classOrder)
                    for k, buf in ipairs(sorted) do
                        local w = buf.widget
                        w:Update(buf, now, sight.timers)
                        w:SetNext(k == nextAt)
                        if l.placed[k] ~= w then
                            l.placed[k] = w
                            local at = l.cells[k]
                            w.frame:ClearAllPoints()
                            w.frame:SetPoint("TOPLEFT", c.frame, "TOPLEFT", at.x, -at.y)
                        end
                    end
                end
            end
        end
    end

    function self.Hide()
        if main then main.frame:Hide() end
        for _, c in ipairs(windows) do c.frame:Hide() end
        wipe(shown)
        wipe(containers)
    end

    return self
end

for k, fn in pairs(new({ parent = UIParent, named = true })) do Panel[k] = fn end
Panel.New = new

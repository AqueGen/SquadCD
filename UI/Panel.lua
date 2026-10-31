local _, ns = ...

local Panel = {}
ns.Panel = Panel

local T = ns.Theme
local Grid, Model = ns.LayoutGrid, ns.LayoutModel
local PAD, LINE_GAP, CELL_GAP, NAME_H, GLYPH_TAB, LABEL_PAD = 6, 6, 2, 11, 11, 3
local NEXT = { Kick = true, Control = true, Stun = true, CC = true, External = true, Group = true }

local UNKNOWN = { ready = true, remaining = 0, recharge = 0, charges = 1, maybe = false, talentsKnown = true }

local main
local windows = {}
local shown = {}
local roleOrder = {}

local function newContainer(name)
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f:SetFrameStrata("MEDIUM")
    return { frame = f, lines = {} }
end

local function mainContainer()
    if main then return main end
    main = newContainer("HuddlePanel")
    T.MakeMovable(main.frame, function() return ns.DB.layout.panel.locked end, function(point)
        ns.DB.layout.panel.point = point
        ns.Display.Rebuild()
    end)
    return main
end

local function window(i)
    windows[i] = windows[i] or newContainer(nil)
    return windows[i]
end

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

local function widgets(c, l, list, bars, size, letters)
    local pool = bars and l.bars or l.icons
    local other = bars and l.icons or l.bars
    for _, w in ipairs(other) do w.frame:Hide() end
    local widest = size
    wipe(l.states)
    wipe(l.placed)
    for k, e in ipairs(list) do
        local w = pool[k] or (bars and ns.KickBars.New(c.frame) or ns.Icon.New(c.frame))
        pool[k] = w
        w.buf.widget = w
        w.entry = e
        w.buf.role = Grid.RoleOf(e.member.spec)
        l.states[k] = w.buf
        if bars then
            w:SetEntry(e.spell, e.member)
        else
            w:SetSpell(e.spell, e.member, size)
            local name = ns.LayoutRules.ShortName(e.member.name or e.member.class or "?", letters)
            widest = math.max(widest, w:SetLabel(name, T.ClassColor(e.member.class)))
        end
        w.frame:Show()
    end
    for k = #list + 1, #pool do pool[k].frame:Hide() end
    l.widgets, l.count = pool, #list
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
        local cellW, cellH = widgets(c, l, item.entries, bars, look.iconSize, look.nameLetters)
        local cells = {}
        for k = 1, #item.entries do cells[k] = { w = cellW, h = cellH } end
        l.type, l.shape, l.labels = item.type, Model.LineShape(layout, item.section, item.type), look.labels
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
        if l.labels == "Glyph" then
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

local function screen()
    return { x = 0, y = 0, w = UIParent:GetWidth(), h = UIParent:GetHeight() }
end

function Panel.Build(list)
    local layout = ns.DB.layout
    roleOrder = Model.RoleOrder(layout)
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

    local scr = screen()
    local loose = {}
    for _, key in ipairs(order) do
        if key ~= "panel" and not sectionOf[key].pos then loose[#loose + 1] = sizes[key] end
    end
    local _, blockW, blockH = Grid.PlaceSections(loose, layout.panelShape, ns.Docking.GAP)
    local positions = { panel = ns.Docking.FromPoint(layout.panel.point, sizes.panel or { w = blockW, h = blockH }, scr) }
    local chain = layout.panelShape.axis == "Columns" and "Right" or "Below"
    local previous = sizes.panel and "panel" or nil
    for _, key in ipairs(order) do
        if key ~= "panel" then
            positions[key] = sectionOf[key].pos
                or { x = positions.panel.x, y = positions.panel.y, dockTo = previous, side = previous and chain, offset = previous and 0 }
            previous = key
        end
    end
    local rects = ns.Docking.Resolve(positions, sizes, scr)
    local unlocked = not layout.panel.locked
    for key, c in pairs(frames) do
        local r = rects[key]
        local f = c.frame
        local look = key == "panel" and layout.panelLook or Model.LookOf(layout, sectionOf[key])
        T.Backdrop(f, look, unlocked)
        f:EnableMouse(key == "panel" and unlocked)
        f:SetSize(r.w, r.h)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", r.x, -r.y)
        f:Show()
    end
end

local function fallback(buf)
    for k, v in pairs(UNKNOWN) do buf[k] = v end
    return buf
end

function Panel.Update(tracker, now, sight)
    for _, c in ipairs(shown) do
        for i = 1, #c.lines do
            local l = c.lines[i]
            if (l.count or 0) > 0 then
                for k = 1, l.count do
                    local w = l.widgets[k]
                    local buf = w.buf
                    local e = w.entry
                    if not tracker:State(e.member.guid, e.spell.id, buf) then fallback(buf) end
                    buf.unknown = buf.ready and ns.LayoutRules.Unknown(e.spell.id, e.own, sight.plain, sight.secret)
                end
                local sorted = Grid.Sort(l.states, l.shape, roleOrder, l.sorted)
                local nextAt = NEXT[l.type] and Grid.Next(sorted, roleOrder)
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

function Panel.SetLocked(locked)
    if InCombatLockdown() then
        print("Huddle: the panel can be locked or unlocked out of combat only.")
        return
    end
    ns.DB.layout.panel.locked = locked
    ns.Display.Rebuild()
end

function Panel.Hide()
    if main then main.frame:Hide() end
    for _, c in ipairs(windows) do c.frame:Hide() end
    wipe(shown)
end

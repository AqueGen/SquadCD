local _, ns = ...

local EditMode = {}
ns.EditMode = EditMode

local T = ns.Theme
local D = ns.Docking

local THRESHOLD = 4
local BAR_TEXT = "Moving the panels: drag a panel, panels snap and dock to each other. Drag moves a docked group, Alt-drag moves one panel."

local panels, members, selected = false, false, 1
local startedDemo = false
local bar, drag
local overlays = {}
local driver = CreateFrame("Frame")

local function blocked(what)
    if not InCombatLockdown() then return false end
    print("Huddle: " .. what .. " is available out of combat only.")
    return true
end

local function refreshWindow()
    if ns.Window then ns.Window.Refresh() end
end

local settingDemo = false

local function setDemo(mode)
    settingDemo = true
    ns.Demo.Set(mode)
    settingDemo = false
end

local function showDemo()
    if ns.Display.HasMembers() or ns.Demo.Running() then return end
    setDemo("Group")
    startedDemo = true
end

local function releaseDemo()
    if panels or members or not startedDemo or InCombatLockdown() then return end
    startedDemo = false
    setDemo("Off")
end

function EditMode.DemoChanged()
    if not settingDemo then startedDemo = false end
end

local function round(v)
    return math.floor(v + 0.5)
end

local function screen()
    return { x = 0, y = 0, w = UIParent:GetWidth(), h = UIParent:GetHeight() }
end

local function scaleOf(f)
    return f:GetEffectiveScale() / UIParent:GetEffectiveScale()
end

local function rectOf(f)
    local s = scaleOf(f)
    return {
        x = f:GetLeft() * s - UIParent:GetLeft(), y = UIParent:GetTop() - f:GetTop() * s,
        w = f:GetWidth() * s, h = f:GetHeight() * s,
    }
end

local function place(f, x, y)
    local s = scaleOf(f)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x / s, -y / s)
end

local function cursor()
    local x, y = GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    return x / s, y / s
end

local function sectionById(id)
    for _, s in ipairs(ns.DB.layout.sections) do
        if s.id == id then return s end
    end
end

local function save(d)
    local rects = {}
    for _, c in ipairs(ns.Panel.Containers()) do rects[c.key] = rectOf(c.frame) end
    local out = D.Drop(rects, d.moving, ns.Panel.Positions())
    for id, r in pairs(rects) do
        local pos = out[id] or ns.Panel.Positions()[id] or {}
        local stored = { x = round(r.x), y = round(r.y) }
        if pos.dockTo then stored.dockTo, stored.side, stored.offset = pos.dockTo, pos.side, round(pos.offset) end
        if id == "panel" then
            ns.DB.layout.panel.point = { "TOPLEFT", stored.x, -stored.y }
        else
            local s = sectionById(id)
            if s then s.pos = stored end
        end
    end
    ns.Display.Rebuild()
end

local function finish()
    local d = drag
    if not d then return end
    drag = nil
    driver:SetScript("OnUpdate", nil)
    if not d.moved then return end
    if InCombatLockdown() then
        ns.Display.Rebuild()
        return
    end
    save(d)
end

local function move()
    local d = drag
    if not IsMouseButtonDown("LeftButton") then
        finish()
        return
    end
    local cx, cy = cursor()
    local dx, dy = cx - d.x0, d.y0 - cy
    if not d.moved and math.abs(dx) + math.abs(dy) < THRESHOLD then return end
    d.moved = true
    local scr = screen()
    local function clamped(x, y)
        local box = { x = d.box.x + x, y = d.box.y + y, w = d.box.w, h = d.box.h }
        local bx, by = D.Clamp(box, scr)
        return x + bx - box.x, y + by - box.y
    end
    dx, dy = clamped(dx, dy)
    local g = d.start[d.key]
    local grabbed = { x = g.x + dx, y = g.y + dy, w = g.w, h = g.h }
    local candidates = D.Near(grabbed, d.anchors, D.SNAP)
    candidates[#candidates + 1] = scr
    local sx, sy = D.Snap(grabbed, candidates)
    dx, dy = clamped(dx + sx - grabbed.x, dy + sy - grabbed.y)
    for id in pairs(d.moving) do
        local r = d.start[id]
        place(d.frames[id], r.x + dx, r.y + dy)
    end
end

local function begin(key)
    if drag or not panels or InCombatLockdown() then return end
    local list, start, frames, at = {}, {}, {}, nil
    for _, c in ipairs(ns.Panel.Containers()) do
        local r = rectOf(c.frame)
        r.id = c.key
        list[#list + 1] = r
        start[c.key], frames[c.key] = r, c.frame
        if c.key == key then at = #list end
    end
    if not at then return end
    local moving = {}
    if IsAltKeyDown() then
        moving[key] = true
    else
        for _, cluster in ipairs(D.Group(list)) do
            for _, i in ipairs(cluster) do
                if i == at then
                    for _, j in ipairs(cluster) do moving[list[j].id] = true end
                end
            end
        end
    end
    local anchors, box = {}, nil
    for _, r in ipairs(list) do
        if moving[r.id] then
            if box then
                local x2, y2 = math.max(box.x + box.w, r.x + r.w), math.max(box.y + box.h, r.y + r.h)
                box.x, box.y = math.min(box.x, r.x), math.min(box.y, r.y)
                box.w, box.h = x2 - box.x, y2 - box.y
            else
                box = { x = r.x, y = r.y, w = r.w, h = r.h }
            end
        else
            anchors[#anchors + 1] = r
        end
    end
    local x0, y0 = cursor()
    drag = { key = key, moving = moving, start = start, frames = frames, anchors = anchors, box = box, x0 = x0, y0 = y0, moved = false }
    driver:SetScript("OnUpdate", move)
end

local function overlayOf(c)
    local o = overlays[c.frame]
    if not o then
        o = CreateFrame("Frame", nil, c.frame, "BackdropTemplate")
        o:SetAllPoints(c.frame)
        o:SetFrameLevel(c.frame:GetFrameLevel() + 20)
        o:SetBackdrop(T.FLAT)
        o:SetBackdropColor(T.gold[1], T.gold[2], T.gold[3], 0.08)
        o:SetBackdropBorderColor(unpack(T.gold))
        o.tag = o:CreateTexture(nil, "ARTWORK")
        o.tag:SetColorTexture(0, 0, 0, 0.8)
        o.name = o:CreateFontString(nil, "OVERLAY")
        o.name:SetFont(T.FONT, 10, "OUTLINE")
        o.name:SetTextColor(unpack(T.gold))
        o.name:SetPoint("TOPLEFT", o, "TOPLEFT", 3, -2)
        o.tag:SetPoint("TOPLEFT", o.name, "TOPLEFT", -2, 1)
        o.tag:SetPoint("BOTTOMRIGHT", o.name, "BOTTOMRIGHT", 2, -1)
        o:EnableMouse(true)
        o:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then begin(self.key) end
        end)
        o:SetScript("OnMouseUp", finish)
        overlays[c.frame] = o
    end
    o.key = c.key
    o.name:SetText(c.name)
    return o
end

local function editBar()
    if bar then return bar end
    bar = CreateFrame("Frame", "HuddleEditBar", UIParent, "BackdropTemplate")
    tinsert(UISpecialFrames, "HuddleEditBar")
    bar:SetFrameStrata("DIALOG")
    bar:SetClampedToScreen(true)
    bar:SetPoint("TOP", UIParent, "TOP", 0, -60)
    T.Panel(bar)
    bar:SetBackdropBorderColor(unpack(T.gold))
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 10, 0)
    text:SetText(BAR_TEXT)
    local done = ns.Widgets.Button(bar, "Done", 70)
    done:SetPoint("RIGHT", -6, 0)
    done:SetScript("OnClick", function() EditMode.StopPanels() end)
    local reset = ns.Widgets.Button(bar, "Reset arrangement", 130)
    reset:SetPoint("RIGHT", done, "LEFT", -6, 0)
    reset:SetScript("OnClick", function() EditMode.ResetArrangement() end)
    bar:SetSize(text:GetStringWidth() + 20 + 130 + 70 + 18, 32)
    bar:SetScript("OnHide", function()
        if panels then EditMode.StopPanels() end
    end)
    return bar
end

function EditMode.Panels()
    return panels
end

function EditMode.Members()
    return members
end

function EditMode.Selected()
    return selected
end

function EditMode.Refresh()
    local shown = {}
    if panels then
        for _, c in ipairs(ns.Panel.Containers()) do
            local o = overlayOf(c)
            o:Show()
            shown[o] = true
        end
    end
    for _, o in pairs(overlays) do
        if not shown[o] then o:Hide() end
    end
    if ns.MemberChip then ns.MemberChip.Refresh() end
end

function EditMode.StartPanels()
    if panels then return true end
    if blocked("Moving the panels") then return false end
    panels = true
    editBar():Show()
    showDemo()
    ns.Display.Rebuild()
    refreshWindow()
    return true
end

function EditMode.StopPanels()
    if not panels then return end
    finish()
    panels = false
    if bar then bar:Hide() end
    EditMode.Refresh()
    ns.Display.Rebuild()
    releaseDemo()
    refreshWindow()
end

function EditMode.TogglePanels()
    if panels then EditMode.StopPanels() else EditMode.StartPanels() end
end

function EditMode.ResetArrangement()
    for _, s in ipairs(ns.DB.layout.sections) do s.pos = nil end
    ns.Display.Changed()
end

function EditMode.StartMembers()
    if members then return true end
    if blocked("Editing at party frames") then return false end
    members, selected = true, 1
    showDemo()
    ns.Display.Rebuild()
    refreshWindow()
    return true
end

function EditMode.StopMembers()
    if not members then return end
    members = false
    EditMode.Refresh()
    releaseDemo()
    refreshWindow()
end

function EditMode.Select(gi)
    if not members or not ns.DB.layout.groups[gi] then return end
    selected = gi
    EditMode.Refresh()
end

function EditMode.EditMembers(edit)
    if not members or blocked("Editing at party frames") then return end
    local layout = ns.DB.layout
    local picked = edit(layout, selected)
    ns.LayoutModel.Normalize(layout)
    if type(picked) == "number" then selected = picked end
    selected = math.max(1, math.min(selected, #layout.groups))
    ns.Display.Changed()
    EditMode.Refresh()
end

driver:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        releaseDemo()
        return
    end
    finish()
    EditMode.StopPanels()
    EditMode.StopMembers()
end)
driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")

ns.Slash("move", function() EditMode.TogglePanels() end)
ns.Slash("frames", function()
    if members then EditMode.StopMembers() else EditMode.StartMembers() end
end)

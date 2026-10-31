-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local T = ns.Theme
local Widgets = ns.Widgets
local Parts = ns.LayoutParts
local Model = ns.LayoutModel
local Preview = ns.Preview

local ROLE_NAMES = { Tank = "Tank", Melee = "Melee", Ranged = "Ranged", Healer = "Healer" }
local ITEM_W, ITEM_H, CLASS_X, CLASS_COLUMNS = 150, 22, 180, 2

local function cancelPreview()
    if Preview.Cancel(ns.DB) then ns.Display.Changed() end
end

local logout = CreateFrame("Frame")
logout:RegisterEvent("PLAYER_LOGOUT")
logout:SetScript("OnEvent", function()
    if ns.DB then Preview.Cancel(ns.DB) end
end)

local function presetCards(page)
    local group = page:Group("Presets")
    group:Note("Click a preset to see it on screen. Apply keeps it, Cancel goes back. Leaving this page also goes back.")
    Parts.PresetCards(group, {
        pick = function(n)
            if ns.EditMode.Panels() or ns.EditMode.Members() then
                print("SquadCD: finish the edit mode first (Done), then preview a preset.")
                return
            end
            Preview.Show(ns.DB, n)
            ns.Display.Changed()
            page:Refresh()
        end,
        used = function() return (Preview.Saved() or ns.DB.layout).preset end,
        showing = Preview.Showing,
    })

    local bar = CreateFrame("Frame", nil, group.frame)
    bar:SetSize(560, 22)
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT")
    text:SetTextColor(0.3, 0.8, 0.4)
    local cancel = Widgets.Button(bar, "Cancel", 80)
    cancel:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    local apply = Widgets.Button(bar, "Apply", 80)
    apply:SetPoint("RIGHT", cancel, "LEFT", -6, 0)
    apply:SetScript("OnClick", function()
        Preview.Apply()
        page:Refresh()
    end)
    cancel:SetScript("OnClick", function()
        cancelPreview()
        page:Refresh()
    end)
    local function previewing() return Preview.Showing() ~= nil end
    group:Add(bar, 22, function()
        local n = Preview.Showing()
        text:SetText("Previewing: " .. (n and Parts.PRESETS[n].name or ""))
    end, previewing)
    group:Note({
        text = "No party? Set the demo above to Whole group to see the preview.",
        visible = function() return previewing() and not ns.Display.HasMembers() and not ns.Demo.Running() end,
    })
    page.frame:HookScript("OnHide", function()
        if not UIParent:IsShown() then return end
        cancelPreview()
    end)
end

local function newItem(parent)
    local item = CreateFrame("Button", nil, parent, "BackdropTemplate")
    item:SetSize(ITEM_W - 6, ITEM_H)
    item:SetBackdrop(T.FLAT)
    item:SetBackdropColor(unpack(T.panel))
    item:RegisterForDrag("LeftButton")
    item.number = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    item.number:SetPoint("LEFT", item, "LEFT", 6, 0)
    item.number:SetTextColor(unpack(T.muted))
    item.label = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    item.label:SetPoint("LEFT", item, "LEFT", 24, 0)
    local hover = item:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.06)
    return item
end

local function priority(page)
    local group = page:Group("Role and class priority")
    group:Note("Who goes first inside every type: the Next marker on kicks, control, externals and raid defensives, and the Fixed icon order.")
    group:Button({
        text = "Reset to default", width = 140,
        onClick = function() Parts.Edit(Model.ResetPriority) end,
    })
    local holder = CreateFrame("Frame", nil, group.frame)
    local roleTitle = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    roleTitle:SetPoint("TOPLEFT")
    roleTitle:SetTextColor(unpack(T.muted))
    roleTitle:SetText("Roles")
    local classTitle = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    classTitle:SetPoint("TOPLEFT", holder, "TOPLEFT", CLASS_X, 0)
    classTitle:SetTextColor(unpack(T.muted))

    local role = "Melee"
    local selected = { list = "role", index = 2 }
    local roles, classes, shownClasses = {}, {}, {}
    local keys = CreateFrame("Frame", nil, holder)

    local function move(list, from, to)
        if list == "role" then
            Parts.Edit(Model.MoveRole, from, to)
        else
            Parts.Edit(Model.MoveClass, role, shownClasses, from, to)
        end
        selected = { list = list, index = to }
        page:Refresh()
    end

    local function listening()
        if InCombatLockdown() then return end
        keys:SetPropagateKeyboardInput(true)
        keys:EnableKeyboard(true)
    end

    keys:SetScript("OnKeyDown", function(self, key)
        if InCombatLockdown() then return end
        local step = (key == "UP" and -1) or (key == "DOWN" and 1) or nil
        local count = selected.list == "role" and 4 or #shownClasses
        local to = step and selected.index + step
        local consume = step ~= nil and IsAltKeyDown() and to >= 1 and to <= count
        self:SetPropagateKeyboardInput(not consume)
        if consume then move(selected.list, selected.index, to) end
    end)
    keys:RegisterEvent("PLAYER_REGEN_DISABLED")
    keys:SetScript("OnEvent", function(self) self:EnableKeyboard(false) end)
    local function deaf()
        if not InCombatLockdown() then keys:EnableKeyboard(false) end
    end
    local function left()
        if not holder:IsMouseOver() then deaf() end
    end
    holder:EnableMouse(true)
    holder:SetScript("OnLeave", left)
    holder:SetScript("OnHide", deaf)

    local function wire(item, list, index)
        item:SetScript("OnClick", function()
            if list == "role" then role = ns.DB.layout.rolePriority[index] end
            selected = { list = list, index = index }
            listening()
            page:Refresh()
        end)
        item:SetScript("OnLeave", left)
        item:SetScript("OnDragStart", function() item.dragging = true end)
        item:SetScript("OnDragStop", function()
            item.dragging = nil
            local pool = list == "role" and roles or classes
            for to, other in ipairs(pool) do
                if other:IsShown() and other:IsMouseOver() and to ~= index then
                    move(list, index, to)
                    return
                end
            end
        end)
    end
    for i = 1, 4 do
        roles[i] = newItem(holder)
        roles[i]:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(18 + (i - 1) * (ITEM_H + 4)))
        wire(roles[i], "role", i)
    end
    for i = 1, #ns.Classes do
        classes[i] = newItem(holder)
        local col, line = (i - 1) % CLASS_COLUMNS, math.floor((i - 1) / CLASS_COLUMNS)
        classes[i]:SetPoint("TOPLEFT", holder, "TOPLEFT", CLASS_X + col * ITEM_W, -(18 + line * (ITEM_H + 4)))
        wire(classes[i], "class", i)
    end

    local height = 0
    group:Add(holder, function() return height end, function()
        local layout = ns.DB.layout
        classTitle:SetText("Class order inside " .. ROLE_NAMES[role])
        for i, item in ipairs(roles) do
            local r = layout.rolePriority[i]
            item.number:SetText(i)
            item.label:SetText(ROLE_NAMES[r] or r)
            item.label:SetTextColor(unpack(r == role and T.gold or T.text))
            local on = selected.list == "role" and selected.index == i
            item:SetBackdropBorderColor(unpack(on and T.gold or T.border))
        end
        shownClasses = ns.LayoutGrid.ClassesIn(layout.classOrder[role], role)
        for i, item in ipairs(classes) do
            local id = shownClasses[i]
            item:SetShown(id ~= nil)
            if id then
                local token = ns.Classes[id]
                item.number:SetText(i)
                item.label:SetText(T.ClassName(token))
                item.label:SetTextColor(T.ClassColor(token))
                local on = selected.list == "class" and selected.index == i
                item:SetBackdropBorderColor(unpack(on and T.gold or T.border))
            end
        end
        local lines = math.max(4, math.ceil(#shownClasses / CLASS_COLUMNS))
        height = 18 + lines * (ITEM_H + 4)
        holder:SetSize(CLASS_X + CLASS_COLUMNS * ITEM_W, height)
    end)
    group:Note("A class counts in the role of its current spec. Click a role to order its classes. Drag a row, or click it and press Alt+Up or Alt+Down.")
    group:Note("Default: Tank > Melee > Ranged > Healer, classes in the game's class list order.")
end

ns.Window.Register("presets", function(page)
    local demo = page:Group("Demo and wizard")
    Parts.Demo(demo)
    demo:Button({
        text = "Layout wizard", width = 140,
        onClick = function() ns.Wizard.Open() end,
    })
    demo:Note("The wizard walks through a preset, the types and their order, then size and position.")
    presetCards(page)
    Parts.TypesTable(page)
    priority(page)
end)

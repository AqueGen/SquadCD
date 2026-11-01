-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Parts = ns.LayoutParts
local Model = ns.LayoutModel

local OVERLAY = { { value = "OnePanel", text = "One panel" }, { value = "Windows", text = "A window per section" } }
local KICKS = { { value = "Bars", text = "Bars" }, { value = "Icons", text = "Icons" } }
local SHOW_WHEN = { { value = "always", text = "Always" }, { value = "group", text = "Only in a group" } }

local function layout()
    return ns.DB.layout
end

local function set(key)
    return function(value)
        Parts.Edit(function(l) l[key] = value end)
    end
end

local function get(key)
    return function() return layout()[key] end
end

local function sectionEditor(page, i)
    local function section() return layout().sections[i] end
    local function own()
        local s = section()
        return s ~= nil and Model.OwnWindow(layout(), s)
    end
    local group = page:Group(function()
        local names = {}
        for k, t in ipairs(section().types) do names[k] = Parts.Label(t) end
        return "Section " .. i .. ": " .. table.concat(names, ", ")
    end)
    group.key = "section:" .. i
    group.visible = function() return section() ~= nil end
    local function edit(fn)
        local s = section()
        if s then Parts.Edit(function(l) fn(l, s) end) end
    end
    group:Note("Click a type to move it left or right, or to turn it off.")
    Parts.Types(group, {
        get = function() return section() and Model.TypeOrder(layout(), section()) or {} end,
        move = function(t, step) Parts.Edit(Model.MoveWithin, "sections", i, t, step) end,
        remove = function(t) Parts.Edit(Model.SetPlace, t, "off") end,
        choices = function()
            local s, out = section(), {}
            if not s then return out end
            for _, t in ipairs(Model.VisibleTypes(layout())) do
                local place, at = Model.PlaceOf(layout(), t)
                if not (place == "panel" and at == i) then out[#out + 1] = t end
            end
            return out
        end,
        add = function(t)
            local s = section()
            if s then Parts.Edit(Model.AddToSection, s.id, t) end
        end,
    })
    group:Check({
        label = "Shown",
        get = function() return section() and section().shown end,
        set = function(on) edit(function(_, s) s.shown = on end) end,
    })
    group:Check({
        label = "Own window",
        tooltip = "This section shows in a window of its own that you can move and dock.",
        get = function() return section() and section().ownWindow end,
        set = function(on) edit(function(_, s) s.ownWindow = on end) end,
        visible = function() return layout().overlay == "OnePanel" end,
    })
    group:Note({ text = "A window per section: this section has its own window.", visible = function() return layout().overlay == "Windows" end })
    group:Check({
        label = "Same shape as the panel",
        get = function() return section() and section().shape == nil end,
        set = function(on) edit(function(l, s) s.shape = not on and ns.Copy(l.panelShape) or nil end) end,
        visible = own,
    })
    Parts.Shape(group, {
        get = function() return section() and section().shape or layout().panelShape end,
        set = function(key, value) edit(function(_, s) if s.shape then s.shape[key] = value end end) end,
        visible = function() return own() and section().shape ~= nil end,
    })
    group:Check({
        label = "Same look as the panel",
        get = function() return section() and section().look == nil end,
        set = function(on) edit(function(l, s) s.look = not on and ns.Copy(l.panelLook) or nil end) end,
    })
    Parts.Look(group, {
        get = function() return section() and section().look or layout().panelLook end,
        set = function(key, value) edit(function(_, s) if s.look then s.look[key] = value end end) end,
        visible = function() return section() ~= nil and section().look ~= nil end,
        backdrop = own,
    })
end

ns.Window.Register("panels", function(page)
    local panels = page:Group("Panels")
    panels.key = "panels"
    panels:Segmented({
        label = "Show cooldowns", options = SHOW_WHEN, width = 260, get = get("showWhen"),
        set = function(value)
            Parts.Edit(function(l) l.showWhen = value end)
            ns.Group.Refresh()
        end,
    })
    panels:Note("Always: your own cooldowns show even without a group, at your frame if one is shown. Only in a group: nothing shows until you join a party.")
    panels:Segmented({ label = "Sections show in", options = OVERLAY, width = 260, get = get("overlay"), set = set("overlay") })
    panels:Note("One panel: every section stacks in one panel, a section can still get its own window. A window per section: each section is its own panel.")
    panels:Button({
        text = "Move the panels", width = 140,
        onClick = function() ns.EditMode.TogglePanels() end,
    })
    panels:Button({ text = "Reset arrangement", width = 140, onClick = function() ns.EditMode.ResetArrangement() end })
    panels:Note("Reset puts every window back next to the panel.")
    panels:Check({ label = "Timers", get = get("timers"), set = set("timers") })
    panels:Note("Seconds left on icons that are on cooldown. Off: the icon only greys out.")
    panels:Segmented({ label = "Kicks in the panel", options = KICKS, get = get("kickStyle"), set = set("kickStyle") })
    panels:Note("Bars: one bar per member that fills as the kick comes back. Icons: one icon per member.")

    local look = page:Group("Panel look and shape")
    look.key = "look"
    look:Note("Every section and window with \"Same as the panel\" uses these.")
    Parts.Look(look, {
        get = function() return layout().panelLook end,
        set = function(key, value) Parts.Edit(function(l) l.panelLook[key] = value end) end,
    })
    Parts.Shape(look, {
        get = function() return layout().panelShape end,
        set = function(key, value) Parts.Edit(function(l) l.panelShape[key] = value end) end,
    })

    local intro = page:Group("Sections")
    intro:Note("One block per section: its types, own window, shape and look. Add a type to a section here, or set a type to Panel on the Presets and types page to give it a section of its own.")
    for i = 1, #ns.LayoutRules.TYPES do sectionEditor(page, i) end
end, { preview = "panel", focus = "panel" })

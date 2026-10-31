-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Parts = ns.LayoutParts
local Model = ns.LayoutModel
local Edit = ns.MemberEdit

local MAX_GROUPS = 8

local function layout()
    return ns.DB.layout
end

local function groupEditor(page, gi)
    local function g() return layout().groups[gi] end
    local group = page:Group("Group " .. gi)
    group.visible = function() return g() ~= nil end
    group:Note("Click a type to turn it off.")
    Parts.Types(group, {
        get = function() return g() and g().types or {} end,
        remove = function(t) Parts.Edit(Edit.ToggleType, gi, t) end,
        choices = function()
            local out = {}
            for _, t in ipairs(Model.VisibleTypes(layout())) do
                local place, at = Model.PlaceOf(layout(), t)
                if not (place == "member" and at == gi) then out[#out + 1] = t end
            end
            return out
        end,
        add = function(t) Parts.Edit(Edit.ToggleType, gi, t) end,
    })
    group:Check({
        label = "Shown",
        get = function() return g() and g().shown end,
        set = function(on) Parts.Edit(function(l) if l.groups[gi] then l.groups[gi].shown = on end end) end,
    })
    group:Segmented({
        label = "Side of the frame", options = Parts.SIDES, width = 280,
        get = function() return g() and g().side end,
        set = function(side) Parts.Edit(Edit.SetSide, gi, side) end,
    })
    Parts.Shape(group, {
        member = true,
        get = function() return g() and g().shape or Model.NewGroup({}, "Left").shape end,
        set = function(key, value)
            if key == "axis" then Parts.Edit(Edit.SetAxis, gi, value)
            elseif key == "perLine" then Parts.Edit(Edit.SetPerLine, gi, value)
            else Parts.Edit(Edit.SetCorner, gi, value) end
        end,
    })
    group:Slider({
        label = "Offset X", min = -Edit.MAX_OFFSET, max = Edit.MAX_OFFSET,
        tooltip = "Left and right is X, up and down is Y, in WoW UI units, -400 to 400.",
        get = function() return g() and g().offsetX or 0 end,
        set = function(v) Parts.Edit(function(l) if l.groups[gi] then l.groups[gi].offsetX = v end end) end,
    })
    group:Slider({
        label = "Offset Y", min = -Edit.MAX_OFFSET, max = Edit.MAX_OFFSET,
        tooltip = "Left and right is X, up and down is Y, in WoW UI units, -400 to 400.",
        get = function() return g() and g().offsetY or 0 end,
        set = function(v) Parts.Edit(function(l) if l.groups[gi] then l.groups[gi].offsetY = v end end) end,
    })
    group:Button({ text = "Reset offset", width = 140, onClick = function() Parts.Edit(Edit.ResetOffset, gi) end })
    group:Check({
        label = "Same look as the party frames default",
        get = function() return g() and g().look == nil end,
        set = function(on) Parts.Edit(function(l) if l.groups[gi] then l.groups[gi].look = not on and ns.Copy(l.memberLook) or nil end end) end,
    })
    Parts.Look(group, {
        member = true,
        get = function() return g() and g().look or layout().memberLook end,
        set = function(key, value) Parts.Edit(Edit.SetLook, gi, key, value) end,
        visible = function() return g() ~= nil and g().look ~= nil end,
    })
    group:Button({
        text = "Remove group", width = 140,
        onClick = function() Parts.Edit(Edit.RemoveGroup, gi) end,
        visible = function() return #layout().groups > 1 end,
    })
end

ns.Window.Register("members", function(page)
    local top = page:Group("At party frames")
    top:Note("Member groups are blocks of icons next to every party frame (Blizzard, EllesmereUI, or a stack of names when neither shows). Each group can hold any type.")
    top:Button({
        text = "Edit at party frames", width = 160,
        onClick = function()
            if ns.EditMode.Members() then ns.EditMode.StopMembers() else ns.EditMode.StartMembers() end
        end,
    })
    top:Note({
        text = function()
            if ns.EditMode.Members() then return "Editing at party frames now. Click the button again to finish." end
            return "Shows a panel of controls at the party frames, so every change shows at once. Out of combat only."
        end,
    })
    top:Check({
        label = "Fit member icons to the frame height",
        get = function() return layout().memberFit end,
        set = function(on) Parts.Edit(function(l) l.memberFit = on end) end,
    })
    top:Note("Icons next to a party frame wrap into rows so they stay within its height. Off: each group's own icons per line decides.")
    top:Button({
        text = "Add group", width = 140,
        onClick = function() Parts.Edit(Edit.AddGroup) end,
        visible = function() return #layout().groups < MAX_GROUPS end,
    })

    local look = page:Group("Party frames default look")
    look:Note("Every group with \"Same look as the party frames default\" uses this look.")
    Parts.Look(look, {
        member = true,
        get = function() return layout().memberLook end,
        set = function(key, value) Parts.Edit(function(l) l.memberLook[key] = value end) end,
    })

    for gi = 1, MAX_GROUPS do groupEditor(page, gi) end
end)

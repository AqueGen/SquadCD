-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local T = ns.SettingsTheme
local Widgets = ns.Widgets
local Preview = ns.Preview

local function profiles(page)
    local P, Switch = ns.Profiles, ns.ProfileSwitch
    local group = page:Group("Profiles")
    group:Note({ color = T.text, text = function() return "Active profile: " .. ns.DB.profile end })
    group:Note("A profile is one panel layout: where the panels sit, their direction and size. Spells and timers are shared by every profile. Each spec of this character can use its own profile; it switches on with the spec. Type a name and press New copy to start a profile from the current layout.")

    local bar = CreateFrame("Frame", nil, group.frame)
    bar:SetSize(450, 22)
    local input = LibStub("LibVelvet-1.0").Input(bar, 120)
    input:SetPoint("LEFT")
    local function typed() return strtrim(input:GetText() or "") end
    local function blocked()
        if ns.EditMode.Panels() or ns.EditMode.Members() then
            print("SquadCD: finish the edit mode first (Done).")
            return true
        end
        if Preview.Cancel(ns.DB) then ns.Display.Changed() end
        return false
    end
    local function button(text, width, anchor, onClick)
        local b = Widgets.Button(bar, text, width)
        b:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
        b:SetScript("OnClick", function()
            onClick()
            page:Refresh()
        end)
        return b
    end
    local new = button("New copy", 80, input, function()
        if blocked() then return end
        if P.New(ns.DB, typed()) then
            input:SetText("")
            ns.Display.Changed()
        else
            print("SquadCD: type a name that no profile has yet.")
        end
    end)
    local rename = button("Rename", 70, new, function()
        if P.Rename(ns.DB, ns.DB.profile, typed()) then
            input:SetText("")
        else
            print("SquadCD: type a new name. Default keeps its name.")
        end
    end)
    local delete = button("Delete", 64, rename, function()
        if blocked() then return end
        if P.Delete(ns.DB, ns.DB.profile) then ns.Display.Changed() end
    end)
    local switch = Widgets.Button(bar, "Switch to...", 84)
    switch:SetPoint("LEFT", delete, "RIGHT", 6, 0)
    switch:SetScript("OnClick", function(self)
        if not MenuUtil then return end
        MenuUtil.CreateContextMenu(self, function(_, root)
            for _, name in ipairs(P.Names(ns.DB)) do
                root:CreateRadio(name, function() return ns.DB.profile == name end, function()
                    Switch.Use(name)
                    page:Refresh()
                end)
            end
        end)
    end)
    group:Add(bar, 22, function()
        rename:SetEnabled(ns.DB.profile ~= P.DEFAULT)
        delete:SetEnabled(ns.DB.profile ~= P.DEFAULT)
    end)

    for _, spec in ipairs(Switch.Specs()) do
        local key = Switch.KeyOf(spec.id)
        local holder = CreateFrame("Frame", nil, group.frame)
        holder:SetSize(Widgets.LABEL_W + Widgets.CONTROL_W, 22)
        local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT")
        label:SetWidth(Widgets.LABEL_W - 8)
        label:SetJustifyH("LEFT")
        local pick = Widgets.Button(holder, "", Widgets.CONTROL_W)
        pick:SetPoint("LEFT", holder, "LEFT", Widgets.LABEL_W, 0)
        pick:SetScript("OnClick", function(self)
            if not MenuUtil then return end
            MenuUtil.CreateContextMenu(self, function(_, root)
                for _, name in ipairs(P.Names(ns.DB)) do
                    root:CreateRadio(name, function() return P.ForSpec(ns.DB, key) == name end, function()
                        P.Assign(ns.DB, key, name ~= P.DEFAULT and name or nil)
                        if spec.id == Switch.CurrentSpec() then Switch.Use(name) end
                        page:Refresh()
                    end)
                end
            end)
        end)
        group:Add(holder, 22, function()
            label:SetText(spec.name .. (spec.id == Switch.CurrentSpec() and " (now)" or ""))
            pick:SetText(P.ForSpec(ns.DB, key))
        end)
    end
end

ns.Window.Register("profiles", profiles, { preview = "panel" })

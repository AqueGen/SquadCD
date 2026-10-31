-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/LayoutGrid.lua",
    "Logic/LayoutRules.lua", "Logic/Docking.lua", "Game/Inspect.lua", "Game/Group.lua", "UI/Theme.lua", "UI/Panel.lua",
    "UI/Display.lua", "UI/Demo.lua", "UI/PanelPreview.lua",
}

local function stub(f)
    return setmetatable(f, {
        __index = function(_, k)
            if not k:match("^%u") then return nil end
            if k:match("^Create") then return function() return stub(helpers.newFrame()) end end
            if k:match("^Get") then return function() return 0 end end
            return function() end
        end,
    })
end

local function fakeIcon()
    local w = { frame = stub(helpers.newFrame()), buf = {} }
    function w:SetSpell() end
    function w:SetLabel() return 20 end
    function w:Update() end
    function w:SetNext() end
    return w
end

local function fakePane()
    local pane = stub(helpers.newFrame())
    pane.stage = stub(helpers.newFrame())
    pane.hooks = {}
    function pane:HookScript(name, fn) self.hooks[name] = fn end
    function pane:SetCaption(text) self.captionText = text end
    function pane:SetOff(text) self.off = text end
    function pane:Fit(content, w, h) self.fit = { content = content, w = w, h = h } end
    function pane:IsVisible() return self.shown and not self.parentHidden end
    return pane
end

describe("Panel preview", function()
    local ns, pane, combat

    before_each(function()
        combat = false
        ns = helpers.load(FILES, {
            CreateFrame = function() return stub(helpers.newFrame()) end,
            UIParent = stub({ GetWidth = function() return 1000 end, GetHeight = function() return 800 end }),
            InCombatLockdown = function() return combat end,
            IsInRaid = function() return false end,
            IsInGroup = function() return false end,
            UnitGUID = function() return "P" end,
            UnitName = function() return nil end,
            GetTime = function() return 100 end,
            C_Timer = { After = function() end },
            C_ClassColor = { GetClassColor = function() return nil end },
            print = function() end,
            wipe = function(t)
                for k in pairs(t) do t[k] = nil end
                return t
            end,
        })
        ns.DB = ns.Defaults({ version = 2, layout = ns.LayoutModel.Defaults() })
        ns.DB.layout.kickStyle = "Icons"
        ns.Icon = { New = fakeIcon, NewTab = function() return { frame = stub(helpers.newFrame()), text = stub(helpers.newFrame()), Set = function() return 10 end } end }
        ns.Rows = { Build = function() end, Update = function() end, Hide = function() end }
        ns.Anchors = { Scan = function() return true end }
        ns.EditMode = { Refresh = function() end, Dragging = function() return false end }
        pane = fakePane()
        ns.PanelPreview.Attach(pane)
    end)

    it("captions the pane, builds the demo panel and starts ticking", function()
        ns.PanelPreview.Refresh()
        assert.are.equal("Preview: the Demo party, 5 members", pane.captionText)
        assert.is_nil(pane.off)
        assert.is_true(pane.fit.w > 0 and pane.fit.h > 0)
        assert.is_function(pane.scripts.OnUpdate)
    end)

    it("follows a settings change", function()
        ns.Display.Changed()
        assert.is_not_nil(pane.fit)
    end)

    it("shows the off line when every type is off", function()
        local layout = ns.DB.layout
        while #layout.sections > 0 do ns.LayoutModel.SetPlace(layout, layout.sections[1].types[1], "off") end
        ns.LayoutModel.Normalize(ns.DB.layout)
        ns.PanelPreview.Refresh()
        assert.are.equal("The panel is empty: every type is off, hidden or at party frames.", pane.off)
        assert.is_nil(pane.scripts.OnUpdate)
    end)

    it("rebuilds in combat without touching the live panel", function()
        combat = true
        ns.Display.Changed()
        assert.is_not_nil(pane.fit)
        assert.are.equal(0, #ns.Panel.Containers())
    end)

    it("stops ticking when the pane hides", function()
        ns.PanelPreview.Refresh()
        pane.hooks.OnHide(pane)
        assert.is_nil(pane.scripts.OnUpdate)
    end)

    it("does nothing while the pane is hidden", function()
        pane:Hide()
        ns.PanelPreview.Refresh()
        assert.is_nil(pane.fit)
    end)

    it("does nothing while the settings window is closed", function()
        pane.parentHidden = true
        ns.Display.Changed()
        assert.is_nil(pane.fit)
    end)

    it("keeps the demo timeline across settings changes and restarts it on refresh", function()
        local made = 0
        local source = ns.Demo.Source
        ns.Demo.Source = function(n)
            made = made + 1
            return source(n)
        end
        ns.PanelPreview.Refresh()
        ns.Display.Changed()
        ns.Display.Changed()
        assert.are.equal(1, made)
        ns.PanelPreview.Refresh()
        assert.are.equal(2, made)
    end)
end)

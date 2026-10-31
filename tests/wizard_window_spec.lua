-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Logic/LayoutModel.lua", "Core.lua", "Logic/LayoutRules.lua", "Logic/Preview.lua", "UI/Theme.lua",
    "UI/WidgetRules.lua", "UI/Widgets.lua", "UI/LayoutParts.lua", "UI/Window.lua", "UI/Wizard.lua",
}
for i = #helpers.VELVET, 1, -1 do table.insert(FILES, 1, helpers.VELVET[i]) end

local function stub(f)
    return setmetatable(f, {
        __index = function(_, k)
            if not k:match("^%u") then return nil end
            if k:match("^Create") then return function(self) return stub(helpers.newFrame()) end end
            if k:match("^Get") then return function() return 0 end end
            return function() end
        end,
    })
end

describe("Wizard window", function()
    local ns, W, created, timers, changed

    local function frame(parent, name)
        local f = stub(helpers.newFrame())
        f.parentFrame, f.name = parent, name
        function f:GetParent() return self.parentFrame or stub(helpers.newFrame()) end
        function f:SetText(t) self.text = t end
        function f:GetText() return self.text end
        function f:Hide()
            local was = self.shown
            self.shown = false
            if was and self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        created[#created + 1] = f
        return f
    end

    local function click(text)
        for _, f in ipairs(created) do
            if f.text == text and f.scripts.OnClick then return f.scripts.OnClick(f) end
        end
        error("no button " .. text)
    end

    local function runTimers()
        local due = timers
        timers = {}
        for _, fn in ipairs(due) do fn() end
    end

    local function shownSettings()
        local n = 0
        for _, f in ipairs(created) do
            if f.name == "SquadCDSettings" and f.shown then n = n + 1 end
        end
        return n
    end

    before_each(function()
        created, timers, changed = {}, {}, 0
        ns = helpers.load(FILES, {
            CreateFrame = function(_, name, parent)
                local f = frame(parent, name)
                if name then _G[name] = f end
                return f
            end,
            InCombatLockdown = function() return false end,
            print = function() end,
            C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end },
            UIParent = stub({}),
            UISpecialFrames = {},
            tinsert = table.insert,
            GameTooltip_Hide = function() end,
        })
        W = ns.Wizard
        ns.DB = ns.Defaults({ version = 2, layout = ns.LayoutModel.Defaults() })
        ns.Display = { Changed = function() changed = changed + 1 end, HasMembers = function() return false end }
        ns.Demo = { Mode = function() return "Off" end, Running = function() return false end, Set = function() end }
        ns.EditMode = { Panels = function() return false end, Members = function() return false end }
        ns.PanelPreview = { Attach = function() end, Refresh = function() end }
        ns.Window.Register("about", function() end)
    end)

    it("cancel puts the layout table back and redraws", function()
        local before = ns.DB.layout
        W.Open()
        assert.is_true(W.IsOpen())
        assert.are_not.equal(before, ns.DB.layout)
        ns.DB.layout.timers = false
        changed = 0
        click("Cancel")
        assert.is_false(W.IsOpen())
        assert.are.equal(before, ns.DB.layout)
        assert.is_true(ns.DB.layout.timers)
        assert.are.equal(1, changed)
    end)

    it("finish keeps the edits", function()
        W.Open()
        local edited = ns.DB.layout
        edited.timers = false
        click("Finish")
        assert.is_false(W.IsOpen())
        assert.are.equal(edited, ns.DB.layout)
        assert.is_false(ns.DB.layout.timers)
    end)

    it("logout with the wizard open puts the layout back", function()
        local before = ns.DB.layout
        W.Open()
        ns.DB.layout.timers = false
        helpers.fire("PLAYER_LOGOUT")
        assert.are.equal(before, ns.DB.layout)
    end)

    it("a hide that comes from UIParent keeps the wizard and its edits", function()
        local before = ns.DB.layout
        W.Open()
        local edited = ns.DB.layout
        edited.timers = false
        SquadCDWizard.scripts.OnHide(SquadCDWizard)
        assert.is_true(W.IsOpen())
        assert.are.equal(edited, ns.DB.layout)
        click("Cancel")
        assert.are.equal(before, ns.DB.layout)
    end)

    it("the settings window stays shut while the wizard is open", function()
        W.Open()
        ns.Window.Show()
        assert.are.equal(0, shownSettings())
        assert.is_true(W.IsOpen())
    end)

    it("the settings window comes back once, after the closing loop", function()
        ns.Window.Show()
        assert.are.equal(1, shownSettings())
        W.Open()
        assert.are.equal(0, shownSettings())
        click("Cancel")
        assert.are.equal(0, shownSettings())
        runTimers()
        assert.are.equal(1, shownSettings())
        assert.is_false(W.IsOpen())
    end)
end)

-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = { "Logic/LayoutModel.lua", "Core.lua", "Logic/Docking.lua", "Logic/MemberEdit.lua", "Logic/Preview.lua", "UI/Theme.lua", "UI/FocusPieces.lua", "UI/EditMode.lua" }

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

local function panelFrame(left, top, w, h)
    local f = { left = left, top = top, w = w, h = h }
    function f:GetLeft() return self.left end
    function f:GetTop() return self.top end
    function f:GetWidth() return self.w end
    function f:GetHeight() return self.h end
    function f:GetEffectiveScale() return 1 end
    function f:GetFrameLevel() return 1 end
    function f:ClearAllPoints() end
    function f:SetPoint(_, _, _, x, y)
        self.left, self.top = x, 800 + y
    end
    return f
end

describe("EditMode", function()
    local ns, E, combat, printed, rebuilds, changed, flushes, demo, cursorX, cursorY, created, mouseDown, members, alt, containers

    local function scriptOf(name)
        for i = #created, 1, -1 do
            if created[i].scripts[name] then return created[i], created[i].scripts[name] end
        end
    end

    before_each(function()
        combat, printed, rebuilds, changed, flushes, demo, members = false, {}, 0, 0, 0, { mode = "Off", calls = {} }, false
        cursorX, cursorY, created, mouseDown = 500, 500, {}, true
        ns = helpers.load(FILES, {
            InCombatLockdown = function() return combat end,
            print = function(s) printed[#printed + 1] = s end,
            CreateFrame = function(_, name, parent)
                local f = stub(helpers.newFrame())
                f.parentFrame = parent
                created[#created + 1] = f
                if name then _G[name] = f end
                return f
            end,
            UIParent = stub({
                GetLeft = function() return 0 end, GetTop = function() return 800 end,
                GetWidth = function() return 1000 end, GetHeight = function() return 800 end,
                GetEffectiveScale = function() return 1 end,
            }),
            UISpecialFrames = {},
            tinsert = table.insert,
            GetCursorPosition = function() return cursorX, cursorY end,
            IsMouseButtonDown = function() return mouseDown end,
            IsAltKeyDown = function() return alt end,
        })
        E = ns.EditMode
        ns.DB = ns.Defaults({})
        alt = false
        containers = { { key = "panel", frame = panelFrame(100, 700, 200, 50), name = "Panel" } }
        ns.Panel = {
            Containers = function() return containers end,
            Positions = function()
                local out = { panel = { x = 100, y = 100 } }
                local kick = ns.DB.layout.sections[1]
                if containers[2] and containers[2].key == "Kick" then out.Kick = kick.pos or { x = 100, y = 100, dockTo = "panel", side = "Below", offset = 0 } end
                local focusDefault = {
                    focus = { x = 306, y = 100, dockTo = "panel", side = "Right", offset = 0 },
                    focuscast = { x = 306, y = 126, dockTo = "focus", side = "Below", offset = 0 },
                }
                for _, c in ipairs(containers) do
                    if focusDefault[c.key] then out[c.key] = ns.DB.layout.focusPos[c.key] or focusDefault[c.key] end
                end
                return out
            end,
        }
        ns.Display = {
            Rebuild = function()
                rebuilds = rebuilds + 1
                E.Refresh()
            end,
            Changed = function() changed = changed + 1 end,
            Flush = function() flushes = flushes + 1 end,
            HasMembers = function() return members end,
        }
        ns.Demo = {
            Running = function() return demo.mode ~= "Off" end,
            Mode = function() return demo.mode end,
            Set = function(m)
                demo.mode = m
                demo.calls[#demo.calls + 1] = m
                E.DemoChanged()
            end,
        }
        ns.Widgets = { Button = function() return stub(helpers.newFrame()) end }
    end)

    it("does nothing in combat and says so", function()
        combat = true
        assert.is_false(E.StartPanels())
        assert.is_false(E.StartMembers())
        assert.is_false(E.Panels())
        assert.is_false(E.Members())
        assert.are.equal(2, #printed)
        assert.truthy(printed[1]:find("out of combat"))
    end)

    it("starting edit mode cancels a preset preview first and says so", function()
        local saved = ns.DB.layout
        ns.Preview.Show(ns.DB, 3)
        assert.is_true(E.StartPanels())
        assert.are.equal(saved, ns.DB.layout)
        assert.is_nil(ns.Preview.Showing())
        assert.truthy(printed[1]:find("preview cancelled"))
        E.StopPanels()
        ns.Preview.Show(ns.DB, 2)
        assert.is_true(E.StartMembers())
        assert.are.equal(saved, ns.DB.layout)
    end)

    it("Move the panels then Done", function()
        assert.is_true(E.StartPanels())
        assert.is_true(E.Panels())
        assert.is_true(rebuilds > 0)
        E.StopPanels()
        assert.is_false(E.Panels())
    end)

    it("Esc hides the bar and ends edit mode", function()
        E.StartPanels()
        SquadCDEditBar:Hide()
        SquadCDEditBar.scripts.OnHide(SquadCDEditBar)
        assert.is_false(E.Panels())
    end)

    it("a bar hidden with UIParent keeps edit mode on", function()
        E.StartPanels()
        SquadCDEditBar.scripts.OnHide(SquadCDEditBar)
        assert.is_true(E.Panels())
    end)

    it("shows the demo when nothing is on screen and stops it after", function()
        E.StartPanels()
        E.StartMembers()
        E.StopPanels()
        assert.are.same({ "Group" }, demo.calls)
        E.StopMembers()
        assert.are.same({ "Group", "Off" }, demo.calls)
    end)

    it("does nothing while the layout wizard is open and says so", function()
        ns.Wizard = { IsOpen = function() return true end }
        assert.is_false(E.StartPanels())
        assert.is_false(E.StartMembers())
        assert.is_false(E.Panels())
        assert.is_false(E.Members())
        assert.are.equal(2, #printed)
        assert.truthy(printed[1]:find("layout wizard"))
    end)

    it("stops its demo when combat ends if combat cut edit mode short", function()
        E.StartPanels()
        combat = true
        helpers.fire("PLAYER_REGEN_DISABLED")
        assert.are.same({ "Group" }, demo.calls)
        combat = false
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.are.same({ "Group", "Off" }, demo.calls)
    end)

    it("leaves a demo the user switched while editing", function()
        E.StartPanels()
        ns.Demo.Set("Me")
        ns.Demo.Set("Group")
        E.StopPanels()
        assert.are.same({ "Group", "Me", "Group" }, demo.calls)
    end)

    it("leaves a live group alone", function()
        members = true
        E.StartPanels()
        E.StopPanels()
        assert.are.same({}, demo.calls)
    end)

    local function dragPanel(dx, dy)
        E.StartPanels()
        local overlay, down = scriptOf("OnMouseDown")
        down(overlay, "LeftButton")
        cursorX, cursorY = cursorX + dx, cursorY - dy
        local driver, update = scriptOf("OnUpdate")
        update(driver, 0.01)
        return driver
    end

    it("saves a dropped panel as a TOPLEFT point", function()
        local driver = dragPanel(60, 30)
        mouseDown = false
        driver.scripts.OnUpdate(driver, 0.01)
        assert.are.same({ "TOPLEFT", 160, -130 }, ns.DB.layout.panel.point)
    end)

    it("is dragging from the press, and a release without a move flushes held rebuilds", function()
        E.StartPanels()
        local overlay, down = scriptOf("OnMouseDown")
        down(overlay, "LeftButton")
        assert.is_true(E.Dragging())
        mouseDown = false
        local driver, update = scriptOf("OnUpdate")
        update(driver, 0.01)
        assert.is_false(E.Dragging())
        assert.are.equal(1, flushes)
    end)

    it("combat start ends both modes and keeps the panel being dragged where it was dropped", function()
        dragPanel(60, 30)
        E.StartMembers()
        helpers.fire("PLAYER_REGEN_DISABLED")
        assert.is_false(E.Panels())
        assert.is_false(E.Members())
        assert.are.same({ "TOPLEFT", 160, -130 }, ns.DB.layout.panel.point)
    end)

    it("discards a drag still held when lockdown has begun", function()
        local before = ns.DB.layout.panel.point
        dragPanel(60, 30)
        combat = true
        helpers.fire("PLAYER_REGEN_DISABLED")
        assert.is_false(E.Panels())
        assert.are.same(before, ns.DB.layout.panel.point)
    end)

    it("Reset arrangement clears stored window spots", function()
        ns.DB.layout.sections[1].pos = { x = 5, y = 5 }
        E.ResetArrangement()
        assert.is_nil(ns.DB.layout.sections[1].pos)
    end)

    it("Reset arrangement in combat goes through Display.Changed", function()
        ns.DB.layout.sections[1].pos = { x = 5, y = 5 }
        combat = true
        E.ResetArrangement()
        assert.is_nil(ns.DB.layout.sections[1].pos)
        assert.are.equal(1, changed)
    end)

    describe("with the focus box right of the panel and its cast below it", function()
        local function drop(key, dx, dy)
            E.StartPanels()
            local frame
            for _, c in ipairs(containers) do
                if c.key == key then frame = c.frame end
            end
            for _, f in ipairs(created) do
                if f.parentFrame == frame and f.scripts.OnMouseDown then f.scripts.OnMouseDown(f, "LeftButton") end
            end
            cursorX, cursorY = cursorX + dx, cursorY - dy
            local driver, update = scriptOf("OnUpdate")
            update(driver, 0.01)
            mouseDown = false
            update(driver, 0.01)
        end

        before_each(function()
            containers[2] = { key = "focus", frame = panelFrame(306, 700, 180, 20), name = "Focus target" }
            containers[3] = { key = "focuscast", frame = panelFrame(306, 674, 180, 20), name = "Focus cast" }
        end)

        it("dragging any focus piece moves all of them and keeps them docked together", function()
            drop("focuscast", 0, 300)
            local pos = ns.DB.layout.focusPos
            assert.are.same({ x = 306, y = 400 }, pos.focus)
            assert.are.same({ x = 306, y = 426, dockTo = "focus", side = "Below", offset = 0 }, pos.focuscast)
            assert.are.equal("Custom", ns.DB.layout.focusArrange)
        end)

        it("an Alt-drag moves one piece alone", function()
            alt = true
            drop("focuscast", 0, 300)
            local pos = ns.DB.layout.focusPos
            assert.are.same({ x = 306, y = 100, dockTo = "panel", side = "Right", offset = 0 }, pos.focus)
            assert.are.same({ x = 306, y = 426 }, pos.focuscast)
        end)
    end)

    describe("with the Kick window docked below the panel", function()
        local function kickPos()
            return ns.DB.layout.sections[1].pos
        end

        local function drop(key, dx, dy)
            E.StartPanels()
            local frame
            for _, c in ipairs(containers) do
                if c.key == key then frame = c.frame end
            end
            for _, f in ipairs(created) do
                if f.parentFrame == frame and f.scripts.OnMouseDown then f.scripts.OnMouseDown(f, "LeftButton") end
            end
            cursorX, cursorY = cursorX + dx, cursorY - dy
            local driver, update = scriptOf("OnUpdate")
            update(driver, 0.01)
            mouseDown = false
            update(driver, 0.01)
        end

        before_each(function()
            containers[2] = { key = "Kick", frame = panelFrame(100, 644, 100, 40), name = "Kick" }
        end)

        it("a drag moves the docked pair and keeps the dock", function()
            drop("panel", 60, 30)
            assert.are.same({ "TOPLEFT", 160, -130 }, ns.DB.layout.panel.point)
            assert.are.same({ x = 160, y = 186, dockTo = "panel", side = "Below", offset = 0 }, kickPos())
        end)

        it("an Alt-drag of the panel leaves Kick undocked where it was", function()
            alt = true
            drop("panel", 300, 0)
            assert.are.same({ "TOPLEFT", 400, -100 }, ns.DB.layout.panel.point)
            assert.are.same({ x = 100, y = 156 }, kickPos())
        end)

        it("a plain drag of a window takes it off the panel alone", function()
            drop("Kick", 0, 300)
            assert.are.same({ "TOPLEFT", 100, -100 }, ns.DB.layout.panel.point)
            assert.are.same({ x = 100, y = 456 }, kickPos())
        end)

        it("snaps a window flush to the right of the panel and docks it", function()
            drop("Kick", 210, -53)
            assert.are.same({ x = 306, y = 100, dockTo = "panel", side = "Right", offset = 0 }, kickPos())
        end)

        it("keeps the moved pair on screen", function()
            drop("panel", -500, 0)
            assert.are.same({ "TOPLEFT", 0, -100 }, ns.DB.layout.panel.point)
            assert.are.same({ x = 0, y = 156, dockTo = "panel", side = "Below", offset = 0 }, kickPos())
        end)
    end)

    describe("member edits", function()
        it("apply to the selected group and select an added group", function()
            E.StartMembers()
            E.EditMembers(ns.MemberEdit.AddGroup)
            assert.are.equal(2, E.Selected())
            E.EditMembers(function(l, gi) return ns.MemberEdit.SetSide(l, gi, "Below") end)
            assert.are.equal("Below", ns.DB.layout.groups[2].side)
            assert.are.equal(2, changed)
        end)

        it("keep the selection on a group that exists after a removal", function()
            E.StartMembers()
            E.EditMembers(ns.MemberEdit.AddGroup)
            E.EditMembers(ns.MemberEdit.RemoveGroup)
            assert.are.equal(1, E.Selected())
            assert.are.equal(1, #ns.DB.layout.groups)
        end)

        it("are ignored outside member edit mode", function()
            E.EditMembers(ns.MemberEdit.AddGroup)
            assert.are.equal(1, #ns.DB.layout.groups)
        end)
    end)
end)

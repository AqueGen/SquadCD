local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = { "Logic/LayoutModel.lua", "Core.lua", "Logic/Docking.lua", "Logic/MemberEdit.lua", "UI/Theme.lua", "UI/EditMode.lua" }

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
    local ns, E, combat, printed, rebuilds, changed, demo, cursorX, cursorY, created, mouseDown, members

    local function scriptOf(name)
        for i = #created, 1, -1 do
            if created[i].scripts[name] then return created[i], created[i].scripts[name] end
        end
    end

    before_each(function()
        combat, printed, rebuilds, changed, demo, members = false, {}, 0, 0, { mode = "Off", calls = {} }, false
        cursorX, cursorY, created, mouseDown = 500, 500, {}, true
        ns = helpers.load(FILES, {
            InCombatLockdown = function() return combat end,
            print = function(s) printed[#printed + 1] = s end,
            CreateFrame = function(_, name)
                local f = stub(helpers.newFrame())
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
            IsAltKeyDown = function() return false end,
        })
        E = ns.EditMode
        ns.DB = ns.Defaults({})
        local panel = panelFrame(100, 700, 200, 50)
        ns.Panel = {
            Containers = function() return { { key = "panel", frame = panel, name = "Panel" } } end,
            Positions = function() return { panel = { x = 100, y = 100 } } end,
        }
        ns.Display = {
            Rebuild = function()
                rebuilds = rebuilds + 1
                E.Refresh()
            end,
            Changed = function() changed = changed + 1 end,
            HasMembers = function() return members end,
        }
        ns.Demo = {
            Running = function() return demo.mode ~= "Off" end,
            Mode = function() return demo.mode end,
            Set = function(m)
                demo.mode = m
                demo.calls[#demo.calls + 1] = m
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

    it("Move the panels then Done", function()
        assert.is_true(E.StartPanels())
        assert.is_true(E.Panels())
        assert.is_true(rebuilds > 0)
        E.StopPanels()
        assert.is_false(E.Panels())
    end)

    it("Esc hides the bar and ends edit mode", function()
        E.StartPanels()
        HuddleEditBar.scripts.OnHide(HuddleEditBar)
        assert.is_false(E.Panels())
    end)

    it("shows the demo when nothing is on screen and stops it after", function()
        E.StartPanels()
        E.StartMembers()
        E.StopPanels()
        assert.are.same({ "Group" }, demo.calls)
        E.StopMembers()
        assert.are.same({ "Group", "Off" }, demo.calls)
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

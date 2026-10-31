-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/LayoutGrid.lua", "Logic/LayoutRules.lua",
    "Game/Inspect.lua", "Game/Group.lua", "UI/Display.lua",
}

describe("Display combat end", function()
    local ns, builds, changed, combat, timers, printed, dragging, noStack

    before_each(function()
        builds, changed, combat, timers, printed = 0, false, false, {}, {}
        ns = helpers.load(FILES, {
            IsInRaid = function() return false end,
            IsInGroup = function() return false end,
            InCombatLockdown = function() return combat end,
            UnitGUID = function() return "P" end,
            UnitName = function() return "Name" end,
            GetTime = function() return 100 end,
            C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end },
            print = function(line) printed[#printed + 1] = line end,
        })
        ns.DB = ns.Defaults({})
        ns.Rows = { Build = function(_, solo) builds, noStack = builds + 1, solo end, Update = function() end, Hide = function() end }
        ns.Panel = { Build = function() end, Update = function() end, Hide = function() end }
        ns.Anchors = { Scan = function() return changed end }
        dragging = false
        ns.EditMode = { Refresh = function() end, Dragging = function() return dragging end }
        local tracker = ns.Tracker.New(function() return 100 end)
        ns.Display.SetSource({ members = { { guid = "P", unit = "player", class = "PALADIN", spec = 66 } }, tracker = tracker })
        builds = 0
    end)

    it("does not rebuild when nothing changed", function()
        helpers.fire("PLAYER_REGEN_ENABLED")
        for _, fn in ipairs(timers) do fn() end
        assert.are.equal(0, builds)
    end)

    it("rebuilds once when anchors changed", function()
        changed = true
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.are.equal(1, builds)
    end)

    it("rebuilds once for a change made in combat", function()
        combat = true
        ns.Display.Rebuild()
        combat = false
        timers = {}
        helpers.fire("PLAYER_REGEN_ENABLED")
        for _, fn in ipairs(timers) do fn() end
        assert.are.equal(1, builds)
    end)

    it("holds rebuilds while a panel is dragged and runs one on flush", function()
        dragging = true
        ns.Display.Rebuild()
        ns.Display.Rebuild()
        assert.are.equal(0, builds)
        dragging = false
        ns.Display.Flush()
        assert.are.equal(1, builds)
        ns.Display.Flush()
        assert.are.equal(1, builds)
    end)

    it("solo live rows get no stack fallback, a demo keeps it", function()
        ns.Display.Rebuild()
        assert.is_false(noStack)
        ns.Display.SetSource(nil)
        ns.Group.OnRoster({ { guid = "P", unit = "player", class = "PALADIN", spec = 66 } })
        assert.is_true(noStack)
    end)

    it("says a change waits for combat end once per combat", function()
        combat = true
        ns.Display.Changed()
        ns.Display.Changed()
        assert.are.equal(1, #printed)
        combat = false
        helpers.fire("PLAYER_REGEN_ENABLED")
        combat = true
        ns.Display.Changed()
        assert.are.equal(2, #printed)
    end)

    it("tells listeners about a change, in combat too, without a combat rebuild", function()
        local heard = 0
        ns.Display.OnChanged(function() heard = heard + 1 end)
        ns.Display.Changed()
        assert.are.equal(1, heard)
        assert.are.equal(1, builds)
        combat = true
        ns.Display.Changed()
        assert.are.equal(2, heard)
        assert.are.equal(1, builds)
    end)

    it("routes members into panel lines", function()
        local lines = ns.Display.Lines({ { guid = "P", unit = "player", class = "PALADIN", spec = 66 } })
        assert.is_true(#lines > 0)
        assert.is_not_nil(lines[1].section)
    end)
end)

describe("Demo source", function()
    it("gives five demo members and a tracker with the DH personal on cooldown", function()
        local list = {}
        for _, f in ipairs(FILES) do list[#list + 1] = f end
        list[#list + 1] = "UI/Demo.lua"
        local ns = helpers.load(list, {
            IsInRaid = function() return false end,
            IsInGroup = function() return false end,
            InCombatLockdown = function() return false end,
            GetTime = function() return 100 end,
            C_Timer = { After = function() end },
        })
        ns.DB = ns.Defaults({})
        local src = ns.Demo.Source(5)
        assert.are.equal(5, #src.members)
        local dh = src.members[1]
        local waiting = 0
        for _, s in ipairs(ns.LayoutRules.SpellsFor(dh, true, {})) do
            local buf = {}
            if s.type == "Personal" and src.tracker:State(dh.guid, s.id, buf) and not buf.ready then waiting = waiting + 1 end
        end
        assert.is_true(waiting > 0)
    end)
end)
